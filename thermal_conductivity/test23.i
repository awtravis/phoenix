# This example calculates the effective thermal conductivity across a microstructure
# with circular second phase precipitates. Two methods are used to calculate the effective thermal conductivity,
# the direct method that applies a temperature to one side and a heat flux to the other,
# and the AEH method.
[Mesh] #Sets mesh size to 10 microns by 10 microns
  type = GeneratedMesh
  dim = 2
  nx = 100
  ny = 100
  xmax = 10
  ymax = 10
[]

[MeshModifiers] #Adds a new node set
  [./new_nodeset]
    type = AddExtraNodeset
    coord = '5 5'
    new_boundary = 100
  [../]
[]

[Variables] #Adds variables needed for two ways of calculating effective thermal cond.
  [./T] #Temperature used for the direct calculation
    initial_condition = 800
  [../]
  [./Tx_AEH] #Temperature used for the x-component of the AEH solve
    initial_condition = 800
    scaling = 1.0e4 #Scales residual to improve convergence
  [../]
  [./Ty_AEH] #Temperature used for the y-component of the AEH solve
    initial_condition = 800
    scaling = 1.0e4  #Scales residual to improve convergence
  [../]
[]

[AuxVariables] #Creates second constant phase
  [./phase2]
  [../]
[]

[ICs] #Sets the IC for the second constant phase
  [./phase2_IC] #Creates circles with smooth interfaces at random locations
    variable = phase2
    type = MultiSmoothCircleIC
    int_width = 0.3
    numbub = 20
    bubspac = 1.5
    radius = 0.5
    outvalue = 0
    invalue = 1
    block = 0
  [../]
[]

[Kernels]
  [./HtCond] #Kernel for direct calculation of thermal cond
    type = HeatConduction
    variable = T
  [../]
  [./heat_conduction_time_derivative]
    type = HeatConductionTimeDerivative
    variable = T
  [../]
  [./heat_x] #All other kernels are for AEH approach to calculate thermal cond.
    type = HeatConduction
    variable = Tx_AEH
  [../]
  [./heat_rhs_x]
    type = HomogenizationHeatConduction
    variable = Tx_AEH
    component = 0
  [../]
  [./heat_y]
    type = HeatConduction
    variable = Ty_AEH
  [../]
  [./heat_rhs_y]
    type = HomogenizationHeatConduction
    variable = Ty_AEH
    component = 1
  [../]
[]

[BCs]
  [./Periodic]
    [./all]
      auto_direction = 'x y'
      variable = 'Tx_AEH Ty_AEH'
    [../]
  [../]
  [./left_T] #Fix temperature on the left side
    type = PresetBC
    variable = T
    boundary = left
    value = 800
  [../]
  [./right_flux] #Set heat flux on the right side
    type = NeumannBC
    variable = T
    boundary = right
    value = 5e-6
  [../]
  [./fix_x] #Fix Tx_AEH at a single point
    type = DirichletBC
    variable = Tx_AEH
    value = 800
    boundary = 100
  [../]
  [./fix_y] #Fix Ty_AEH at a single point
    type = DirichletBC
    variable = Ty_AEH
    value = 800
    boundary = 100
  [../]
[]

[Materials]
  [./steel]
    type = GenericConstantMaterial
    block = 0
    prop_names = 'thermal_conductivity specific_heat density'
    prop_values = '18 0.466 8000' # W/m*K, J/kg-K, kg/m^3 @ 296K
  [../]
[]

[Postprocessors]
  [./right_T]
    type = SideAverageValue
    variable = T
    boundary = right
  [../]
  [./k_x_direct] #Effective thermal conductivity from direct method
    # This value is lower than the AEH value because it is impacted by second phase
    # on the right boundary
    type = ThermalCond
    variable = T
    flux = 5e-6
    length_scale = 1e-06
    T_hot = 800
    dx = 10
    boundary = right
  [../]
  [./k_x_AEH] #Effective thermal conductivity in x-direction from AEH
    type = HomogenizedThermalConductivity
    variable = Tx_AEH
    temp_x = Tx_AEH
    temp_y = Ty_AEH
    component = 0
    scale_factor = 1e6 #Scale due to length scale of problem
  [../]
  [./k_y_AEH] #Effective thermal conductivity in x-direction from AEH
    type = HomogenizedThermalConductivity
    variable = Ty_AEH
    temp_x = Tx_AEH
    temp_y = Ty_AEH
    component = 1
    scale_factor = 1e6 #Scale due to length scale of problem
  [../]
[]

[Preconditioning]
  [./SMP]
    type = SMP
    off_diag_row = 'Tx_AEH Ty_AEH'
    off_diag_column = 'Ty_AEH Tx_AEH'
  [../]
[]

[Executioner]
  type = Transient
  scheme = 'bdf2'
  solve_type = 'NEWTON'

  l_max_its = 15
  l_tol = 1.0e-4

  nl_max_its = 10
  nl_rel_tol = 1.0e-4

  start_time = 0.0
  num_steps = 10

  [./TimeStepper]
  type = IterationAdaptiveDT
  dt = .001 # Initial time step.
  optimal_iterations = 6 # Time step will adapt to maintain this number of nonlinear iterations
  [../]
[]

[Outputs]
  execute_on = 'timestep_end'
  exodus = true
  csv = true
[]
