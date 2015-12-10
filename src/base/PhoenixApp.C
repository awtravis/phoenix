#include "PhoenixApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "ModulesApp.h"
#include "MooseSyntax.h"
#include "Micro.h"

template<>
InputParameters validParams<PhoenixApp>()
{
  InputParameters params = validParams<MooseApp>();

  params.set<bool>("use_legacy_uo_initialization") = false;
  params.set<bool>("use_legacy_uo_aux_computation") = false;
  params.set<bool>("use_legacy_output_syntax") = false;

  return params;
}

PhoenixApp::PhoenixApp(InputParameters parameters) :
    MooseApp(parameters)
{
  Moose::registerObjects(_factory);
  ModulesApp::registerObjects(_factory);
  PhoenixApp::registerObjects(_factory);

  Moose::associateSyntax(_syntax, _action_factory);
  ModulesApp::associateSyntax(_syntax, _action_factory);
  PhoenixApp::associateSyntax(_syntax, _action_factory);
}

PhoenixApp::~PhoenixApp()
{
}

// External entry point for dynamic application loading
extern "C" void PhoenixApp__registerApps() { PhoenixApp::registerApps(); }
void
PhoenixApp::registerApps()
{
  registerApp(PhoenixApp);
}

// External entry point for dynamic object registration
extern "C" void PhoenixApp__registerObjects(Factory & factory) { PhoenixApp::registerObjects(factory); }
void
PhoenixApp::registerObjects(Factory & factory)
{
  registerObject(Micro);
}

// External entry point for dynamic syntax association
extern "C" void PhoenixApp__associateSyntax(Syntax & syntax, ActionFactory & action_factory) { PhoenixApp::associateSyntax(syntax, action_factory); }
void
PhoenixApp::associateSyntax(Syntax & /*syntax*/, ActionFactory & /*action_factory*/)
{
}
