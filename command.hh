#ifndef command_hh
#define command_hh

#include "simpleCommand.hh"

// Command Data Structure

struct Command {
  std::vector<SimpleCommand *> _simpleCommands;
  std::string * _outFile;
  std::string * _inFile;
  std::string * _errFile;
  bool _append;
  bool _background;
  bool _ambig;

  Command();
  void insertSimpleCommand( SimpleCommand * simpleCommand );

  void clear();
  void print();
  void execute();

  int inputRedirect(int defaultin);
  int outputRedirect(int defaultout);
  int errorRedirect(int defaulterr);

  static SimpleCommand *_currentSimpleCommand;
};

#endif
