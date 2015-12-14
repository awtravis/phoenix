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
#ifndef KEFF_H_
#define KEFF_H_

#include "Material.h"

class keff;

template<>
InputParameters validParams<keff>();

/**
 * Material objects inherit from Material and override computeQpProperties.
 *
 * Their job is to declare properties for use by other objects in the
 * calculation such as Kernels and BoundaryConditions.
 */
class keff : public Material
{
public:
  keff(const InputParameters & parameters);

protected:
  /**
   * Necessary override.  This is where the values of the properties
   * are computed.
   */
  virtual void computeQpProperties();


  /// The temperature (T)
  MaterialProperty<Real> & _temperature;

  /// The concentration (c)
  MaterialProperty<Real> & _concentration;

  /// The thermal conductivity (k)
  MaterialProperty<Real> & _thermal_conductivity;

};

#endif //keff_H
