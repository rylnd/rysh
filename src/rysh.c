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

int checkArguments(char* tokens[], int idx_in_token, int token_number, int num_tokens) {
  char* token_with_operand = tokens[token_number];

  if (token_number == num_tokens - 1) { // last token has >
    if (strlen(token_with_operand) - 1 == idx_in_token) { // last char >, error
      printError();
    }
  }
  else if (!token_number && !idx_in_token) { // operand is not preceded by anything
    printError();
  }
  else if (strlen(token_with_operand) - 1 == idx_in_token) { // not last token, but end of token
    if (tokens[token_number + 1]) {
      if (tokens[token_number + 2]) {
        printError();
      }
      else { return 1; }
    }
    else { printError(); }

    if (!tokens[token_number - 1]) {
      printError();
    }
  }

  return 0;
}

// HANDLE REDIRECTS
void redirect(char* tokens[], int idx_in_token, int token_number, int num_tokens) {

  char* token_with_redirect = tokens[token_number];
  char* file = NULL;
  clearError();

  if (checkArguments(tokens, idx_in_token, token_number, num_tokens)) {
    file = tokens[token_number + 1];
  }

  if (!lastError) { // no error, need file
    if (!file) {
      file = strndup(token_with_redirect + (idx_in_token + 1), strlen(token_with_redirect) - (idx_in_token + 1));
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
        tokens[token_number] = NULL;
        execvp(tokens[0], tokens);
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
void zip(char* tokens[], int idx_in_token, int token_number, int num_tokens) {

  char* token_with_zip = tokens[token_number];
  char* file = NULL;
  int fds[2];

  clearError();

  if (checkArguments(tokens, idx_in_token, token_number, num_tokens)) {
    file = tokens[token_number + 1];
  }

  if (!lastError) { // no error, need file
    if (!file) {
      file = strndup(token_with_zip + (idx_in_token + 1), strlen(token_with_zip) - (idx_in_token + 1));
    }

    int rd = fork();
    pipe(fds);
    if (!rd) { // child 1
      int rd2 = fork();
      if (!rd2) { // child 2
        close(fds[0]); // close stdout
        dup2(fds[1], STDOUT);
        tokens[token_number] = NULL;
        execvp(tokens[0], tokens);
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

void forkCmd(char* tokens[]) {

  int rd = fork();

  if (!rd) { // Child
    execvp(tokens[0], tokens);
    printError();
    exit(1);
  }
  else if (rd > 0) { // Parent
    wait(NULL);
  }
  else { printError(); }
}

// HANDLE OTHERS
void runCmd(char* tokens[], int token_count, int output) {

  char buffer[4096];

  if (!strcmp("exit", tokens[0])) {
    if (!tokens[1]) { exit(0); }
    else { printError(); }
  }
  else if (!strcmp("pwd", tokens[0])) {
    char* result = getcwd(buffer,4096);
    if (!result) {
      printError();
      exit(1);
    }
    if (tokens[1]) { printError(); }
    else {
      char *newline = strdup("\n");
      write(output, buffer, strlen(buffer));
      write(output, newline , strlen(newline));
    }
  }
  else if (!strcmp("cd", tokens[0])) {
    char* dir;
    if (!tokens[1]) {
      dir = getenv("HOME");
    }
    else {
      dir = tokens[1];
    }

    if (chdir(dir)) { printError(); }
  }
  else { // NOT BUILT-IN

    int token_idx;
    int num_redirects = 0;
    int num_zips = 0;
    char* redir_index;
    char* zip_index;

    for (token_idx = 0; token_idx < token_count; token_idx++) {
      zip_index = strchr(tokens[token_idx], ':');
      redir_index = strchr(tokens[token_idx], '>');

      if (zip_index) { // HAS ZIP
        num_zips++;
        if (redir_index) {
          num_redirects++;
        }
        else if (num_zips == 1) {
          zip(tokens, zip_index - tokens[token_idx], token_idx, token_count);
        }
      }
      else if (redir_index) { // HAS REDIRECT, NO ZIP
        num_redirects++;
        if (num_redirects == 1) {
          redirect(tokens, redir_index - tokens[token_idx], token_idx, token_count);
        }
      }
    }

    if (!num_zips && !num_redirects) {
      forkCmd(tokens);
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
  char *command_tokens[1024];

  if (!file) { printf("rysh> "); }

  while (fgets(buffer, sizeof(buffer), input)) {

    if (file) { write(STDOUT, buffer, strlen(buffer)); }

    if (strlen(buffer) > 512) {
      printError();
    }
    else { // split by semicolon
      char* statements[1024];
      int num_statements = 0;
      if (!strchr(buffer, ';')) {
        statements[0] = buffer;
      }
      else {
        char* token = strtok(buffer, ";");
        while (token) {
          statements[num_statements++] = token;
          token = strtok(NULL, ";");
        }
      }
      int k;
      for (k = 0; k <= num_statements; k++) { // split by whitespace
        char* temp = strtok(statements[k], " \t\n");
        command_tokens[0] = temp;
        int token_count = 1;

        while (temp) {
          temp = strtok(NULL, " \t\n");
          command_tokens[token_count++] = temp;
        }

        if (command_tokens[0]) {
          command_tokens[token_count] = NULL;
          runCmd(command_tokens, token_count - 1, STDOUT);
        }
      }

      if (!file) { printf("rysh> "); }
    }
  }

  return 0;
}
