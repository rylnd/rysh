#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

//struct for holding key and string
typedef struct {
  int key;
  char* strVal;

}simPair;

static int lastError = 0;

void clearError(){
  lastError = 0;
}

void printError(){
  char error_message[30] = "An error has occurred\n";
  write(STDERR_FILENO, error_message, strlen(error_message));
  lastError = 1;
}

// NEEDED ON 10.6, strndup not built in
char* strndup(const char* s, size_t n) {
  size_t l = strlen(s);
  char *r = NULL;

  if (l < n)
    return strdup(s);

  r = (char *) malloc(n+1);
  if (r == NULL)
    return NULL;

  strncpy(r, s, n);
  r[n] ='\0';
  return r;
}

/*
int isMult(char* tok){
  int i;
  int isM = 0;
  for(i = 0; i < strlen(tok); i++){
    if(tok[i] == ';')isM = 1;
  }
  return isM;
}
*/

//HANDLE REDIRECTS
void red(char* cmd[], int loc, int index, int len){

  char* curr = cmd[index];
  char* file = NULL;
  clearError();

  if(index == len-1){//last token has >
    if((strlen(curr)-1)==loc){//last char >, error
      printError();
    }

  }
  else if(strlen(curr)-1==loc){//not last token, but end of token
    if(cmd[index+1] != NULL){
      if(cmd[index+2]!=NULL){
        printError();
      }
      else
        file = cmd[index+1];
    }
    else{
      printError();
    }
    if(cmd[index - 1]==NULL){
      printError();
    }

  }
  else if(index ==0){//first token
    if(loc==0){//first char
      printError();
    }
  }

  if(!lastError){//no error, need file
    if(file==NULL){
      file = strndup(curr + (loc+1), strlen(curr) - (loc+1));
    }
    //DUP2 HANDLING*****

    int rd = fork();
    if (rd == 0){//Child
      close(STDOUT_FILENO);
      int f = open(file, O_WRONLY|O_CREAT, S_IRWXU);
      if(f==-1){
        printError();
      }
      else{
        cmd[index] = NULL;
        execvp(cmd[0], cmd);
        printError();
        exit(1);
      }
    }

    else if (rd > 0){//Parent
      wait(NULL);
    }
    else{
      printError();
    }
  }
}
  //HANDLE ZIPS
void zip(char* cmd[], int loc, int index, int len){

  char* curr = cmd[index];
  char* file = NULL;
  int fds[2];

  clearError();

  if(index == len-1){//last token has >
    if((strlen(curr)-1)==loc){//last char >, error
      printError();
    }

  }
  else if(strlen(curr)-1==loc){//not last token, but end of token
    if(cmd[index+1] != NULL){
      if(cmd[index+2]!=NULL){
        printError();
      }
      else
        file = cmd[index+1];
    }
    else{
      printError();
    }
    if(cmd[index - 1]==NULL){
      printError();
    }

  }
  else if(index ==0){//first token
    if(loc==0){//first char
      printError();
    }
  }

  if(!lastError){//no error, need file
    if(file==NULL){
      file = strndup(curr + (loc+1), strlen(curr) - (loc+1));
      //check if exists
    }

    int rd=fork();
    pipe(fds);
    if(rd==0){//child 1
      int rd2 = fork();
      if(rd2 == 0){//child 2
        close(fds[0]);//close stdout
        dup2(fds[1], STDOUT_FILENO);
        cmd[index] = NULL;
        execvp(cmd[0], cmd);
        printError();
        exit(1);
      }
      else if(rd2>0){//parent 2
        wait(NULL);
        close(fds[1]);
        close(STDOUT_FILENO);
        int f = open(file, O_WRONLY|O_CREAT, S_IRWXU);
        if(f==-1){
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
      else printError();
    }
    else if(rd > 0){wait(NULL);}
    else{printError();}
  }
}

void forkCmd(char* cmd[]){

  int rd = fork();
  if (rd == 0){//Child
    execvp(cmd[0], cmd);
    printError();
    exit(1);
  }

  else if (rd > 0){//Parent
    wait(NULL);
  }
  else
    printError();
}


//HANDLE OTHERS
void runCmd(char* cmd[], int len, int output){
  char buffer[4096];

  if(strcmp("exit", cmd[0])==0){
    if(cmd[1]==NULL)exit(0);
    else{ printError();}
  }
  else if(strcmp("pwd", cmd[0])==0){
    char* err = getcwd(buffer,4096);
    if(err==NULL){
      printError();
      exit(1);
    }
    if(cmd[1]!=NULL)printError();
    else{
      char *nl = strdup("\n");
      write(output, buffer, strlen(buffer));
      write(output, nl , strlen(nl));
    }
  }
  else if(strcmp("cd", cmd[0])==0){
    int err;
    char* dir;
    if(cmd[1]==NULL){
      dir = getenv("HOME");
      err = chdir(dir);
    }
    else{
      dir = cmd[1];
      err = chdir(dir);
    }
    if(err!=0)printError();
  }
  else{//NOT BUILT-IN

    //CHECK for redirects
    int l;
    int redf = 0;
    int zipf = 0;
    int err = 0;
    char* redc;
    char* zipc;
    int forkc = 0;

    for(l = 0; l < len-1; l++){
      zipc = strchr(cmd[l], ':');
      redc = strchr(cmd[l], '>');

      if(zipc != NULL){//HAS ZIP
        zipf++;
        if(redc != NULL){err = 1;redf++;}
        else if(zipf==1){
          zip(cmd, zipc-cmd[l], l, len-1);
        }
      }
      else if (redc != NULL){//HAS RED, NO ZIP
        redf++;
        if(redf==1){
          red(cmd, redc-cmd[l], l, len-1);
        }
      }
      else{forkc++;}

    }

    if(zipf==0 && redf==0){
      forkCmd(cmd);
    }
  }
}


int main(int argc, char *argv[])
{
  FILE *input;
  int file = 0;
  if(argc !=2 && argc != 1){
    printError();
    exit(1);
  }
  else if(argc==1) input = stdin;
  else {
    input = fopen(argv[1], "r");
    if(input == NULL){
      printError();
      exit(1);
    }
    else file=1;
  }

  int BUF_SIZE = 4096;
  int OUTPUT = STDOUT_FILENO;
  char buffer[BUF_SIZE];
  char *commands[1024];
  if(!file)printf("rysh> ");
  while(fgets(buffer, sizeof(buffer), input)){
    if(strlen(buffer) > 512){
      if(file){
        write(STDOUT_FILENO, buffer, strlen(buffer));
         }
      printError();
    }
    else{
    //SPLIT UP STRING
    //FIRST, by ;

    char* cmds[1024];
    int q = 1;
    if(file)write(STDOUT_FILENO, buffer, strlen(buffer));
    if(strchr(buffer, ';')==NULL){
      cmds[0] = buffer;
      q = 1;

    }
    else{
      char* cmd = strtok(buffer, ";");
      cmds[0] = cmd;
      while(cmd != NULL){
        cmd = strtok(NULL, ";");
        cmds[q] = cmd;
        q++;
      }
      q--;
    }
    int k;
    for(k = 0; k < q; k++){//EACH COMMAND ON LINE
      char* temp = strtok(cmds[k], " \t\n");
      commands[0] = temp;
      int j = 1;

      while(temp != NULL){
        temp = strtok(NULL, " \t\n");
        commands[j] = temp;
        j++;
      }


      if(commands[0] != NULL){
        commands[j] = NULL;
        runCmd(commands, j, OUTPUT);
      }
    }

    if(!file)printf("rysh> ");
    }
  }

  return 0;
}
