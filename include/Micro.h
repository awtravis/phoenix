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
#ifndef MICRO_H_
#define MICRO_H_

#include "Material.h"

// A helper class from MOOSE that linear interpolates x,y data
#include "LinearInterpolation.h"

class Micro;

template<>
InputParameters validParams<Micro>();

/**
 * Material objects inherit from Material and override computeQpProperties.
 *
 * Their job is to declare properties for use by other objects in the
 * calculation such as Kernels and BoundaryConditions.
 */
class Micro : public Material
{
public:
  Micro(const InputParameters & parameters);

protected:
  /**
   * Necessary override.  This is where the values of the properties
   * are computed.
   */
  virtual void computeQpProperties();

  /// The concentration (c)
  MaterialProperty<Real> & _concentration;

  /// The bulk thermal conductivity
  MaterialProperty<Real> & _thermal_conductivity;

  /// The bulk heat capacity
  MaterialProperty<Real> & _heat_capacity;

  /// The bulk density
  MaterialProperty<Real> & _density;

  /// Flag for using the phase for porosity
  bool _use_phase_variable;

  /// The coupled phase variable
  const VariableValue & _phase;

  /// Flag for using a variable for thermal conductivity
  bool _use_variable_conductivity;

  /// The coupled thermal conductivity
  const VariableValue & _conductivity_variable;
};

#endif //Micro_H
