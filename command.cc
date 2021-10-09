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

void Command::execute() {
    // Don't do anything if there are no simple commands
    if ( _simpleCommands.size() == 0 ) {
        Shell::prompt();
        return;
    }
    //IF the output is ambiguous, print and exit
    if (_ambig) {
        fprintf(stderr, "Ambiguous output redirect.\n");
        Shell::prompt();
        return;
    }

    // Print contents of Command data structure
    if (isatty(0)) {
      print();
    }

    //// Default I/O ////
    int defaultin = dup(0);
    int defaultout = dup(1);
    int defaulterr = dup(2);

    int inFile = 0;
    int outFile = 0;
    int errFile = 0;

    ////File Redirection ////
        //In File
        if (_inFile) {
           inFile = open(_inFile->c_str(), O_RDONLY);
            if (inFile < 0) {
                perror("open");
                clear();
                Shell::prompt();
                return;
                //exit(1); // Delete If we don't want to exit shell?
            }
        } else {
           inFile = dup(defaultin);
        }

        //Error file
        if (_errFile) {
            if (_append) {
                errFile = open(_errFile->c_str(), O_WRONLY | O_APPEND | O_CREAT, 0655);
            } else {
                errFile = open(_errFile->c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0655);
            }
            if (errFile < 0) {
                perror("open");
                clear();
                Shell::prompt();
                return;
                //exit(1);
            }
        } else {
            errFile = dup(defaulterr);
        }
        dup2(errFile, 2);
        close(errFile);


    // Add execution here
    // For every simple command fork a new process
    // Setup i/o redirection
    // and call exec
    int index = 0;
    for (auto & simpleCommand: _simpleCommands) {
        index += 1;

        dup2(inFile, 0);
        close(inFile);

        //// PIPES //// ~Slide 261

        //Out File
         //If it is last commnand, Set the output to the file, or stdout
        if (index == _simpleCommands.size()) {
            if (_outFile) {
                if (_append) {
                    outFile = open(_outFile->c_str(), O_WRONLY | O_APPEND | O_CREAT, 0655);
                } else {
                    outFile = open(_outFile->c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0655);
                }
                if (outFile < 0) {
                    perror("open");
                    clear();
                    Shell::prompt();
                    return;
                    //exit(1);
                }
            } else {
                outFile = dup(defaultout);
            }
        } else {
            //Otherwise, we direct the output to pipes
            int fdpipe[2];
            pipe(fdpipe);
            outFile = fdpipe[1];
            inFile = fdpipe[0];
        }

        dup2(outFile, 1);
        close(outFile);


        int pid = fork();

        if (pid == -1) {
            perror("fork\n");
            clear();
            Shell::prompt();
            return;
            //_exit(2);
        }


        if (pid == 0) {
            //CHILD
            int size = simpleCommand->_arguments.size();
            char ** simpCmds = new char*[size + 1];
            for (int i = 0; i < size; i++) {
                simpCmds[i] = strdup(simpleCommand->_arguments[i]->c_str());
            }
            simpCmds[size] = NULL;
            execvp(simpCmds[0], simpCmds);

            perror("xecvp");
            clear();
            Shell::prompt();
            return;
            //_exit(1);
        } // End child

        //PARENT
        if (_background == false) {
            waitpid(pid, NULL, 0);
        }
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
