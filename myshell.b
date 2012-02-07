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

void printError(){
	char error_message[30] = "An error has occurred\n";
	write(STDERR_FILENO, error_message, strlen(error_message));
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
	int flag=0; 
	//printf("redirect\n");		
	//printf("length:%d  index: %d\n", strlen(curr)-1, loc);
	//printf("length2:%d  index2: %d\n",len-1, index)  ;
	if(index == len-1){//last token has >
		if((strlen(curr)-1)==loc){//last char >, error
		printError();
		flag = 1;	
		}
		
	}
	else if(strlen(curr)-1==loc){//not last token, but end of token
			if(cmd[index+1] != NULL){
				file = cmd[index+1]; 
			}
			else{printError(); flag = 1;}
	}
	else if(index ==0){//first token
		if(loc==0){//first char
		printError();
		flag = 1;
		}
	}
	
	if(flag==0){//no error, need file
		if(file==NULL){
			//printf("size:%d\n", strlen(curr) - (loc + 1));
			file = strndup(curr + (loc+1), strlen(curr) - (loc+1));
			//check if exists
		}
		//DUP2 HANDLING*****
	
		//if(fopen(file, "r")==NULL){
		//printf("file: %s\n", file);
			
			int rd = fork();
			if (rd == 0){//Child
				//close(STDOUT_FILENO);
				int f = open(file, O_WRONLY|O_CREAT, S_IRWXU);
				if(f==-1){
					printError();
					//exit(1);
				}
				
				else{
				//runCmd(cmd, len, f);
				//exit(0);
				execvp(cmd[0], cmd);
				printError();
				exit(1);
				}
			}
	
			else if (rd > 0){//Parent
				wait(NULL);
				//printf("waited for: %d\n", (int) wc);
			}
			else
				printError();
			/*
			if(dup2(f, 1) < 0){
				printError();
			}
			else{
				runCmd(cmd, len, f);	
				close(f);
			}
			*/	
		
	}



}
//HANDLE ZIPS
void zip(char* cmd[], int loc, int index, int len){
	
}

void
forkCmd(char* cmd[]){

	int rd = fork();
	if (rd == 0){//Child
		execvp(cmd[0], cmd);
		printError();
		exit(1);
	}

	else if (rd > 0){//Parent
		wait(NULL);
		//printf("waited for: %d\n", (int) wc);
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
		

		
		
		forkCmd(cmd);
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
	if(!file)printf("myshell> ");
	while(fgets(buffer, sizeof(buffer), input)){
		//printf("Line: %s\n", buffer);
		//printf("line size:%d\n", strlen(buffer)); 
		//printf("last char:\"%c\"\n", buffer[strlen(buffer)-2]); 
		//if((buffer[512] != EOF) && (buffer[512] != ']') && (buffer[512] != '\n')){
		if(strlen(buffer) > 512){	
			if(file){
				write(STDOUT_FILENO, buffer, strlen(buffer)); 
			
				//printf("too long\n");
				 }
			printError();
			//printf("buffer[511]: %s\n", buffer[511]);
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
				//printf("q:%d\n", q);
			}
			q--;
		}	
		int k; 
		for(k = 0; k < q; k++){//EACH COMMAND ON LINE  
			char* temp = strtok(cmds[k], " \t\n");
			commands[0] = temp;
			int j = 1;
			//printf("i:%d \t%s\n", 0,  commands[0]);
			while(temp != NULL){
				temp = strtok(NULL, " \t\n"); 
				//printf("com[%d]: %*.*s\n",i, len, len, tok); 
				commands[j] = temp;
				//printf("i:%d \t%s\n", j,  commands[j]);

				//printf("temp size: %d\n", strlen(temp));
				//printf("isize: %d\n", i);
				j++; 
			}
			//CHECK for redirects 
			int l;
			int redf = 0;
			int zipf = 0;		
			int err = 0;
			char* redc;
			char* zipc;
			int reg = 0;

                      for(l = 0; l < j-1; l++){
                                zipc = strchr(commands[l], ':');
                                redc = strchr(commands[l], '>');

                                if(zipc != NULL){//HAS ZIP
                                        zipf++;
                                        if(redc != NULL){err = 1;redf++;}
                                        else if(zipf==1){
                                                zip(commands, zipc-commands[l], l, j-1);
                                        }
                                }
                                else if (redc != NULL){//HAS RED, NO ZIP
                                        redf++;
                                        if(redf==1){
                                        red(commands, redc-commands[l], l, j-1);
                                        }
                                }
				else{reg=1;}



                        }



			if(reg==1){
				commands[j] = NULL;
				runCmd(commands, j, OUTPUT);
			}
				
		
		
		} 

		if(!file)printf("myshell> ");
		//printf("%s\n", tok);
		}
	}
	


	
	
	/*char buffer[80];
  	//write last char to x for overrun check
 	buffer[78] = 'x';
   
        simPair *sortArray;    
        sortArray =(simPair*) malloc(sizeof(simPair) * 10);

	FILE * input;	

	if(argc != 2)
	{//incorrect number of arguments, print usage
		fprintf(stderr, "Usage: mysort <filename>\n");
		exit(1);
	}

	input = fopen(argv[1], "r"); //open for readint
	//}
	if(input == NULL)
	{
		fprintf(stderr, "Error: Cannot open file\n");
		exit(1);
	}
	
	fgets(buffer, 80, input);
	

	int n = -1;
	int max = 10;

	//make a simPair
	simPair temp;
    while(!feof(input))
	{	
		n++;
		if((buffer[78] != EOF) && (buffer[78] != 'x') && (buffer[78] != '\n')){
			//over 80 characters in line
			fprintf(stderr, "Error: Line too long\n");
			exit(1);
		}
		//save line
		temp.strVal = (char*) malloc(strlen(buffer) + 1);  
	        strcpy(temp.strVal, buffer);

		//split into tokens
                char *tok = strtok(buffer, " \t\n"); 
		if(tok != NULL){
			if(isNum(tok, strlen(tok)))
			temp.key = atoi(tok); 
			else temp.key = 0;
			//printf("%d: " , temp.key);
		}
		else{temp.key = 0;}
		//printf("%s \n" , temp.strVal);
		
		//check size
		if(n >= max){//need to realloc
			max = max*2;
			sortArray = (simPair*) realloc(sortArray, max*sizeof(simPair));
		}    	
		sortArray[n] = temp;  
		//write last char to x for overrun check
		buffer[78] = 'x';
		fgets(buffer, 80, input);
		
	}

	fclose(input);

	//sort array
	qsort(sortArray, n + 1, sizeof(simPair), sortFn);
	int i;
	//print array value back out
	for(i=0; i <= n; i++){
		//printf("array[%d]%d: %s\n",i,  sortArray[i].key, sortArray[i].strVal);
		printf("%s", sortArray[i].strVal);
	}  
	*/
	return 0;
}

