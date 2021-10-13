/*
 * CS252: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 * DO NOT PUT THIS PROJECT IN A PUBLIC REPOSITORY LIKE GIT. IF YOU WANT 
 * TO MAKE IT PUBLICALLY AVAILABLE YOU NEED TO REMOVE ANY SKELETON CODE 
 * AND REWRITE YOUR PROJECT SO IT IMPLEMENTS FUNCTIONALITY DIFFERENT THAN
 * WHAT IS SPECIFIED IN THE HANDOUT. WE OFTEN REUSE PART OF THE PROJECTS FROM  
 * SEMESTER TO SEMESTER AND PUTTING YOUR CODE IN A PUBLIC REPOSITORY
 * MAY FACILITATE ACADEMIC DISHONESTY.
 */

#include <cstdio>
#include <cstdlib>
#include <unistd.h>
#include <iostream>
#include <sys/wait.h>
#include <string.h>
#include "command.hh"
#include "shell.hh"
#include <fcntl.h>
#include <sys/stat.h>

Command::Command() {
    // Initialize a new vector of Simple Commands
    _simpleCommands = std::vector<SimpleCommand *>();

    _outFile = NULL;
    _inFile = NULL;
    _errFile = NULL;
    _background = false;
    _append = false;
    _ambig = false;
}

void Command::insertSimpleCommand( SimpleCommand * simpleCommand ) {
    // add the simple command to the vector
    _simpleCommands.push_back(simpleCommand);
}

void Command::clear() {
    // deallocate all the simple commands in the command vector
    for (auto simpleCommand : _simpleCommands) {
        delete simpleCommand;
    }

    // remove all references to the simple commands we've deallocated
    // (basically just sets the size to 0)
    _simpleCommands.clear();

    if ( _outFile ) {
        delete _outFile;
    }

    if ( _inFile != _outFile) {
        delete _inFile;
    }

    if ( _errFile != _outFile) {
        delete _errFile;
    }
    _outFile = NULL;
    _inFile = NULL;
    _errFile = NULL;

    _background = false;

    _append = false;

    _ambig = false;
}

void Command::print() {
    printf("\n\n");
    printf("              COMMAND TABLE                \n");
    printf("\n");
    printf("  #   Simple Commands\n");
    printf("  --- ----------------------------------------------------------\n");

    int i = 0;
    // iterate over the simple commands and print them nicely
    for ( auto & simpleCommand : _simpleCommands ) {
        printf("  %-3d ", i++ );
        simpleCommand->print();
    }

    printf( "\n\n" );
    printf( "  Output       Input        Error        Background\n" );
    printf( "  ------------ ------------ ------------ ------------\n" );
    printf( "  %-12s %-12s %-12s %-12s\n",
            _outFile?_outFile->c_str():"default",
            _inFile?_inFile->c_str():"default",
            _errFile?_errFile->c_str():"default",
            _background?"YES":"NO");
    printf( "\n\n" );
}

int Command::inputRedirect(int defaultin) {
  //This function opens the apropriate input file in read only
  //If an input file is not specified, it is set to default
    if (_inFile) {
        return open(_inFile->c_str(), O_RDONLY);
    } else {
       return dup(defaultin);
    }
}

int Command::outputRedirect(int defaultout) {
  //This function opens the appropriate out file with either O_APPEND or
  //O_TRUNC, depending on if the file needs to be appeneded or not
  //If there is no out file specified, it is set to default
    if (_outFile) {
        if (_append) {
            return open(_outFile->c_str(), O_WRONLY | O_APPEND | O_CREAT, 0655);
        } else {
            return open(_outFile->c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0655);
        }
    } else {
        return dup(defaultout);
    }
 }

int Command::errorRedirect(int defaulterr) {
  //This function opens the errfile
  //If none is specified, it is set to default
    if (_errFile) {
        if (_append) {
            return open(_errFile->c_str(), O_WRONLY | O_APPEND | O_CREAT, 0655);
        } else {
            return open(_errFile->c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0655);
        }
   } else {
        return dup(defaulterr);
   }
}

void Command::execute() {
    int size = _simpleCommands.size();
    // Don't do anything if there are no simple commands
    if ( _simpleCommands.size() == 0 ) {
        Shell::prompt();
        return;
    }
    //If the output is ambiguous, print and exit
    if (_ambig) {
        fprintf(stderr, "Ambiguous output redirect.\n");
        Shell::prompt();
        return;
    }
    //If the user writes "exit" we exit the shell
    if (size == 1 && (strcmp(_simpleCommands[0]->_arguments[0]->c_str(), "exit"))== 0) {
        fprintf(stderr, "\n Goodbye!!\n\n");
        exit(0);
    }

    // Print contents of Command data structure
    if (isatty(0)) {
      print();
    }

    //// File Redirection ////
    int defaultin = dup(0);
    int defaultout = dup(1);
    int defaulterr = dup(2);

    int inFile = 0;
    int outFile = 0;
    int errFile = 0;

    inFile = inputRedirect(defaultin);
    if (inFile < 0) {
      //if there was an error when opening a file, we print the error, clear
      //the command obj and print a new prompt
        perror(_inFile->c_str());
        clear();
        Shell::prompt();
        return;
    }

    errFile = errorRedirect(defaulterr);
    if (errFile < 0) {
      //if there was an error when opening a file, we print the error, clear
      //the command obj and print a new prompt
        perror(_errFile->c_str());
        clear();
        Shell::prompt();
        return;
    }
    dup2(errFile, 2);
    close(errFile);
    //// End File Redirection ////

    // Add execution here
    // For every simple command fork a new process
    // Setup i/o redirection
    // and call exec
    int index = 0;
    for (auto & simpleCommand: _simpleCommands) {
        index += 1;

        dup2(inFile, 0);
        close(inFile);

        //// PIPES ////
        //Out File
        if (index == size) {
          //If it is last commnand, Set the output to the file, or stdout
            outFile = outputRedirect(defaultout);
            if (outFile < 0) {
              //if there was an error when opening a file, we print the error, clear
              //the command obj and print a new prompt
                perror(_outFile->c_str());
                clear();
                Shell::prompt();
                return;
            }
        } else {
          //Otherwise, we direct the input and output to pipes
            int fdpipe[2];
            pipe(fdpipe);
            outFile = fdpipe[1];
            inFile = fdpipe[0];
        }

        dup2(outFile, 1);
        close(outFile);
        //// END PIPES ////

        //// Built In Functions ////
        //printenv
        /*if (strcmp(simpleCommand->_arguments[0]->c_str(), "printenv") == 0) {
            int e = 0;
            while(environ[e]) {
                printf("%s\n", environ[e++]);
            }
            continue;
        }*/

        //setenv
        if (strcmp(simpleCommand->_arguments[0]->c_str(), "setenv") == 0) {
            setenv(simpleCommand->_arguments[1], simpeCommand->_arguments[2]);
            continue;
        }


        //CD
        if (strcmp(simpleCommand->_arguments[0]->c_str(), "cd") == 0) {
            int cmdSize = simpleCommand->_arguments.size();
            if (cmdSize == 1) {
                if (chdir(getenv("HOME")) != 0) {
                    perror("cd");
                    clear();
                    Shell::prompt();
                    return;
                }
            } else if (cmdSize == 2) {
                if (chdir(simpleCommand->_arguments[1]->c_str()) != 0) {
                    perror(simpleCommand->_arguments[1]->c_str());
                    clear();
                    Shell::prompt();
                    return;
                }
            }
            continue;
        }


        int pid = fork();

        if (pid == -1) {
            perror("fork\n");
            clear();
            Shell::prompt();
            return;
        }

        //// CHILD ////
        if (pid == 0) {
            int size = simpleCommand->_arguments.size();
            char ** simpCmds = new char*[size + 1];
            for (int i = 0; i < size; i++) {
                simpCmds[i] = strdup(simpleCommand->_arguments[i]->c_str());
            }
            simpCmds[size] = NULL;
            execvp(simpCmds[0], simpCmds);

            perror("xecvp");
            _exit(1);
        }
        //// END CHILD ////

        //// PARENT ////
        if (_background == false) {
            waitpid(pid, NULL, 0);
        }
        //// END PARENT ////
    } // End simpleCommand Loop

    //// Resetting File I/O ////
    dup2(defaultin, 0);
    dup2(defaultout, 1);
    dup2(defaulterr, 2);
    close(defaultin);
    close(defaultout);
    close(defaulterr);

    // Clear to prepare for next command
    clear();

    // Print new prompt
    Shell::prompt();
} // End Command::execute()

SimpleCommand * Command::_currentSimpleCommand;
