#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

// struct for holding key and string
typedef struct {
  int key;
  char* strVal;

}simPair;

static int lastError = 0;
static int STDOUT = STDOUT_FILENO;

void clearError() { lastError = 0; }

void printError() {
  char error_message[30] = "An error has occurred\n";
  write(STDERR_FILENO, error_message, strlen(error_message));
  lastError = 1;
}

// NEEDED ON 10.6, strndup not built in
char* strndup(const char* s, size_t n) {

  size_t l = strlen(s);
  char* r = NULL;

  if (l < n)
    return strdup(s);

  r = (char*) malloc(n + 1);
  if (r == NULL)
    return NULL;

  strncpy(r, s, n);
  r[n] ='\0';
  return r;
}

/*
int isMult(char* tok) {
  int i;
  int isM = 0;
  for (i = 0; i < strlen(tok); i++) {
    if (tok[i] == ';') { isM = 1; }
  }
  return isM;
}
*/

int checkArguments(char* cmds[], int loc, int operand_index, int num_cmds) {
  char* operand = cmds[operand_index];

  if (operand_index == num_cmds - 1) { // last token has >
    if (strlen(operand) - 1 == loc) { // last char >, error
      printError();
    }
  }
  else if (!operand_index && !loc) { // operand is not preceded by anything
    printError();
  }
  else if (strlen(operand) - 1 == loc) { // not last token, but end of token
    if (cmds[operand_index + 1]) {
      if (cmds[operand_index + 2]) {
        printError();
      }
      else { return 1; }
    }
    else { printError(); }

    if (!cmds[operand_index - 1]) {
      printError();
    }
  }

  return 0;
}

// HANDLE REDIRECTS
void redirect(char* cmds[], int loc, int redir_index, int num_cmds) {

  char* redir_char = cmds[redir_index];
  char* file = NULL;
  clearError();

  if (checkArguments(cmds, loc, redir_index, num_cmds)) {
    file = cmds[redir_index + 1];
  }

  if (!lastError) { // no error, need file
    if (!file) {
      file = strndup(redir_char + (loc + 1), strlen(redir_char) - (loc + 1));
    }
    // DUP2 HANDLING*****
    int rd = fork();

    if (!rd) { // Child
      close(STDOUT);
      int f = open(file, O_WRONLY|O_CREAT, S_IRWXU);
      if (f == -1) {
        printError();
      }
      else {
        cmds[redir_index] = NULL;
        execvp(cmds[0], cmds);
        printError();
        exit(1);
      }
    }
    else if (rd > 0) { // Parent
      wait(NULL);
    }
    else { printError(); }
  }
}

// HANDLE ZIPS
void zip(char* cmds[], int loc, int zip_index, int num_cmds) {

  char* curr = cmds[zip_index];
  char* file = NULL;
  int fds[2];

  clearError();

  if (checkArguments(cmds, loc, zip_index, num_cmds)) {
    file = cmds[zip_index + 1];
  }

  if (!lastError) { // no error, need file
    if (!file) {
      file = strndup(curr + (loc + 1), strlen(curr) - (loc + 1));
    }

    int rd = fork();
    pipe(fds);
    if (!rd) { // child 1
      int rd2 = fork();
      if (!rd2) { // child 2
        close(fds[0]); // close stdout
        dup2(fds[1], STDOUT);
        cmds[zip_index] = NULL;
        execvp(cmds[0], cmds);
        printError();
        exit(1);
      }
      else if (rd2 > 0) { // parent 2
        wait(NULL);
        close(fds[1]);
        close(STDOUT);
        int f = open(file, O_WRONLY|O_CREAT, S_IRWXU);
        if (f == -1) {
          printError();
        }
        dup2(fds[0], STDIN_FILENO);
        char* zip[2];
        zip[0] = strdup("gzip");
        zip[1] = NULL;
        execvp(zip[0], zip);
        printError();
        exit(1);
      }
      else { printError(); }
    }
    else if (rd > 0) { wait(NULL); }
    else { printError(); }
  }
}

void forkCmd(char* cmds[]) {

  int rd = fork();

  if (!rd) { // Child
    execvp(cmds[0], cmds);
    printError();
    exit(1);
  }
  else if (rd > 0) { // Parent
    wait(NULL);
  }
  else { printError(); }
}

// HANDLE OTHERS
void runCmd(char* cmds[], int cmd_count, int output) {

  char buffer[4096];

  if (!strcmp("exit", cmds[0])) {
    if (!cmds[1]) { exit(0); }
    else { printError(); }
  }
  else if (!strcmp("pwd", cmds[0])) {
    char* result = getcwd(buffer,4096);
    if (!result) {
      printError();
      exit(1);
    }
    if (cmds[1]) { printError(); }
    else {
      char *newline = strdup("\n");
      write(output, buffer, strlen(buffer));
      write(output, newline , strlen(newline));
    }
  }
  else if (!strcmp("cd", cmds[0])) {
    char* dir;
    if (!cmds[1]) {
      dir = getenv("HOME");
    }
    else {
      dir = cmds[1];
    }

    if (chdir(dir)) { printError(); }
  }
  else { // NOT BUILT-IN

    int cmd_number;
    int num_redirects = 0;
    int num_zips = 0;
    char* redir_index;
    char* zip_index;

    for (cmd_number = 0; cmd_number < cmd_count; cmd_number++) {
      zip_index = strchr(cmds[cmd_number], ':');
      redir_index = strchr(cmds[cmd_number], '>');

      if (zip_index) { // HAS ZIP
        num_zips++;
        if (redir_index) {
          num_redirects++;
        }
        else if (num_zips == 1) {
          zip(cmds, zip_index - cmds[cmd_number], cmd_number, cmd_count);
        }
      }
      else if (redir_index) { // HAS REDIRECT, NO ZIP
        num_redirects++;
        if (num_redirects == 1) {
          redirect(cmds, redir_index - cmds[cmd_number], cmd_number, cmd_count);
        }
      }
    }

    if (!num_zips && !num_redirects) {
      forkCmd(cmds);
    }
  }
}

int main(int argc, char *argv[]) {

  FILE *input;
  int file = 0;

  switch (argc) {
    case 1:
      input = stdin;
      break;
    case 2:
      input = fopen(argv[1], "r");
      if (!input) {
        printError();
        exit(1);
      }
      file = 1;
      break;
    default:
      printError();
      exit(1);
  }

  int BUF_SIZE = 4096;
  char buffer[BUF_SIZE];
  char *commands[1024];

  if (!file) { printf("rysh> "); }

  while (fgets(buffer, sizeof(buffer), input)) {

    if (file) { write(STDOUT, buffer, strlen(buffer)); }

    if (strlen(buffer) > 512) {
      printError();
    }
    else { // split by semicolon
      char* cmdTokens[1024];
      int numCmds = 0;
      if (!strchr(buffer, ';')) {
        cmdTokens[0] = buffer;
      }
      else {
        char* token = strtok(buffer, ";");
        while (token) {
          cmdTokens[numCmds++] = token;
          token = strtok(NULL, ";");
        }
      }
      int k;
      for (k = 0; k <= numCmds; k++) { // split by whitespace
        char* temp = strtok(cmdTokens[k], " \t\n");
        commands[0] = temp;
        int cmd_count = 1;

        while (temp) {
          temp = strtok(NULL, " \t\n");
          commands[cmd_count++] = temp;
        }

        if (commands[0]) {
          commands[cmd_count] = NULL;
          runCmd(commands, cmd_count - 1, STDOUT);
        }
      }

      if (!file) { printf("rysh> "); }
    }
  }

  return 0;
}
