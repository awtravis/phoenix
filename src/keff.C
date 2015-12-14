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
#include "keff.h"
#include "math.h"

template<>
InputParameters validParams<keff>()
{
  InputParameters params = validParams<Material>();

  params.addCoupledVar("concentration", "The variable indicating the oxygen concentration (U4O9=0.25 or UO2=0). If supplied this is used to compute the interface instead of the supplied value.");
  params.addCoupledVar("temperature", "The variable indicating the temperature at a point on the microstructure.");
  params.addCoupledVar("thermal_conductivity", "Output");

  return params;
}


keff::keff(const InputParameters & parameters) :
    Material(parameters),


    // Declare material properties.  This returns references that we
    // hold onto as member variables

    _temperature(declareProperty<Real>("temperature")),
    _concentration(declareProperty<Real>("concentration")),
    _thermal_conductivity(declareProperty<Real>("thermal_conductivity"))
{
}

void
keff::computeQpProperties()
{

  // Compute the functional form of the thermal conductivity of UO2+X
    Real A = 0.0257+(3.336*_concentration[_qp]);      // [m/W]
    Real C = 0.2206-(0.685*_concentration[_qp]);      // [mK/W]
    Real t = (_temperature[_qp])/(1000);              // [K]

  // Now actually set the value at the quadrature point

    _thermal_conductivity[_qp] = ((1)/(A+(C*t)))+(pow(7410.53*t,-5/2))*exp(-16.35/t);
}
