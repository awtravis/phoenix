#ifndef PHOENIXAPP_H
#define PHOENIXAPP_H

#include "MooseApp.h"

class PhoenixApp;

template<>
InputParameters validParams<PhoenixApp>();

class PhoenixApp : public MooseApp
{
public:
  PhoenixApp(InputParameters parameters);
  virtual ~PhoenixApp();

  static void registerApps();
  static void registerObjects(Factory & factory);
  static void associateSyntax(Syntax & syntax, ActionFactory & action_factory);
};

#endif /* PHOENIXAPP_H */
