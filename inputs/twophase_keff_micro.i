# U4O9 domains in a UO2 matrix
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
    initial_condition = 573
  [../]
  [./Tx_AEH] #Temperature used for the x-component of the AEH solve
    initial_condition = 573
    scaling = 1.0e4 #Scales residual to improve convergence
  [../]
  [./Ty_AEH] #Temperature used for the y-component of the AEH solve
    initial_condition = 573
    scaling = 1.0e4  #Scales residual to improve convergence
  [../]

  [./c]   # Mole fraction of Cr (unitless)
    order = FIRST
    family = LAGRANGE
  [../]
  [./w]   # Chemical potential (eV/mol)
    order = FIRST
    family = LAGRANGE
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
    variable = c
  [../]
[]

[Kernels]
  [./HtCond] #Kernel for direct calculation of thermal cond
    type = HeatConduction
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
  [./w_dot]
    variable = w
    v = c
    type = CoupledTimeDerivative
  [../]
  [./coupled_res]
    variable = w
    type = SplitCHWRes
    mob_name = M
  [../]
  [./coupled_parsed]
    variable = c
    type = SplitCHParsed
    f_name = f_loc
    kappa_name = kappa_c
    w = w
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
    value = 573
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
    value = 573
    boundary = 100
  [../]
  [./fix_y] #Fix Ty_AEH at a single point
    type = DirichletBC
    variable = Ty_AEH
    value = 573
    boundary = 100
  [../]
[]

[Materials]
  [./thcond] #The equation defining the thermal conductivity is defined here, using two ifs
    # The k in the bulk is k_b, in the precipitate k_p2, and across the interaface k_int
    type = ParsedMaterial
    block = 0
    constant_names = 'length_scale k_b k_p2 k_int'
    constant_expressions = '1e-6 5.999 1.500 0.1'
    function = 'sk_b:= length_scale*k_b; sk_p2:= length_scale*k_p2; sk_int:= k_int*length_scale; if(phase2>0.1,if(phase2>0.95,sk_p2,sk_int),sk_b)'
    outputs = exodus
    f_name = thermal_conductivity
    args = phase2
  [../]

  # d is a scaling factor that makes it easier for the solution to converge
  # without changing the results. It is defined in each of the materials and
  # must have the same value in each one.
  [./constants]
    # Define constant values kappa_c and M. Eventually M will be replaced with
    # an equation rather than a constant.
    type = GenericFunctionMaterial
    block = 0
    prop_names = 'kappa_c M'
    prop_values = '8.125e-16*6.24150934e+18*1e+09^2*1e-27
                   2.2841e-26*1e+09^2/6.24150934e+18/1e-27'
                   # kappa_c*eV_J*nm_m^2*d
                   # M*nm_m^2/eV_J/d
  [../]
  [./local_energy]
    # Defines the function for the local free energy density as given in the
    # problem, then converts units and adds scaling factor.
    type = DerivativeParsedMaterial
    block = 0
    f_name = f_loc
    args = c
    constant_names = 'A   B   C   D   E   F   G  eV_J  d'
    constant_expressions = '-2.446831e+04 -2.827533e+04 4.167994e+03 7.052907e+03
                            1.208993e+04 2.568625e+03 -2.354293e+03
                            6.24150934e+18 1e-27'
    function = 'eV_J*d*(A*c+B*(1-c)+C*c*log(c)+D*(1-c)*log(1-c)+
                E*c*(1-c)+F*c*(1-c)*(2*c-1)+G*c*(1-c)*(2*c-1)^2)'
    derivative_order = 2
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
    T_hot = 573
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

  [./step_size]             # Size of the time step
    type = TimestepSize
  [../]
  [./iterations]            # Number of iterations needed to converge timestep
    type = NumNonlinearIterations
  [../]
  [./nodes]                 # Number of nodes in mesh
    type = NumNodes
  [../]
  [./evaluations]           # Cumulative residual calculations for simulation
    type = NumResidualEvaluations
  [../]
  [./active_time]           # Time computer spent on simulation
    type = RunTime
    time_type = active
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
  solve_type = NEWTON
  l_max_its = 30
  l_tol = 1e-6
  nl_max_its = 50
  nl_abs_tol = 1e-9
  end_time = 604800   # 7 days
  petsc_options_iname = '-pc_type -ksp_grmres_restart -sub_ksp_type
                         -sub_pc_type -pc_asm_overlap'
  petsc_options_value = 'asm      31                  preonly
                         ilu          1'
  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 10
    cutback_factor = 0.8
    growth_factor = 1.5
    optimal_iterations = 7
  [../]
  [./Adaptivity]
    coarsen_fraction = 0.1
    refine_fraction = 0.7
    max_h_level = 2
  [../]
[]

[Outputs]
  execute_on = 'timestep_end'
  exodus = true
  csv = true
  console = true
  [./console]
    type = Console
    max_rows = 10
  [../]
[]
