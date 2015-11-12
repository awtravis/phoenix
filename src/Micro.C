/****************************************************************/
/*               DO NOT MODIFY THIS HEADER                      */
/* MOOSE - Multiphysics Object Oriented Simulation Environment  */
/*                                                              */
/*           (c) 2010 Battelle Energy Alliance, LLC             */
/*                   ALL RIGHTS RESERVED                        */
/*                                                              */
/*          Prepared by Battelle Energy Alliance, LLC           */
/*            Under Contract No. DE-AC07-05ID14517              */
/*            With the U. S. Department of Energy               */
/*                                                              */
/*            See COPYRIGHT for full restrictions               */
/****************************************************************/
#include "Micro.h"

template<>
InputParameters validParams<Micro>()
{
  InputParameters params = validParams<Material>();

  params.addCoupledVar("phase", "The variable indicating the phase (U4O9=1 or UO2=0). If supplied this is used to compute the interface instead of the supplied value.");
  params.addCoupledVar("thermal_conductivity", "When supplied the variable be will be used for thermal conductivity rather than being computed.");
  return params;
}


Micro::Micro(const InputParameters & parameters) :
    Material(parameters),


    // Declare two material properties.  This returns references that we
    // hold onto as member variables
    _concentration(declareProperty<Real>("concentration")),
    _thermal_conductivity(declareProperty<Real>("thermal_conductivity")),
    _heat_capacity(declareProperty<Real>("heat_capacity")),
    _density(declareProperty<Real>("density")),
    _use_phase_variable(isParamValid("phase")),
    _phase(_use_phase_variable ? coupledValue("phase") : _zero),
    _use_variable_conductivity(isParamValid("thermal_conductivity")),
    _conductivity_variable(_use_variable_conductivity ? coupledValue("thermal_conductivity") : _zero)
{
}

void
Micro::computeQpProperties()
{

  // Compute the heat conduction material properties as a linear combination of
  // the material properties for UO2 and U4O9.

  // If the phase variable is given use it
    if (_use_phase_variable)
      _concentration[_qp] = _phase[_qp];

    else
      _concentration[_qp] = _phase[_qp];

  // We will compute a "bulk" thermal conductivity, specific heat and density
  // as a linear combination of the UO2 and U4O9
  Real UO2_k = 6.9;  // (W/m*K)
  Real UO2_cp = 275; // (J/kg*K)
  Real UO2_rho = 10970;  // (kg/m^3 @ 303K)

  Real U4O9_k = 1.5;  // (W/m*K)
  Real U4O9_cp = 275;  // (J/kg*K)
  Real U4O9_rho = 11130;  // (kg/m^3)

  // Now actually set the value at the quadrature point
  if (_use_variable_conductivity)
    _thermal_conductivity[_qp] = _conductivity_variable[_qp];
  else
    _thermal_conductivity[_qp] = (1-(_concentration[_qp]*_concentration[_qp]))*UO2_k + (_concentration[_qp]*_concentration[_qp])*U4O9_k;
  _density[_qp] = (1-_concentration[_qp])*UO2_rho + _concentration[_qp]*U4O9_rho;
  _heat_capacity[_qp] = (1-_concentration[_qp])*UO2_cp*UO2_rho + _concentration[_qp]*U4O9_cp*U4O9_rho;
}
