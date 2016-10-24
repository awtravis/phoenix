[Functions]
  [./my_image]
    type = ImageFunction
    file = color.png
  [../]
[]

[ICs]
  [./u_ic]
    type = FunctionIC
    function = my_image
    variable = u
  [../]
[]

[Adaptivity]
  max_h_level = 5
  initial_steps = 5
  initial_marker = marker
  [./Indicators]
    [./indicator]
      type = GradientJumpIndicator
      variable = u
    [../]
  [../]
  [./Markers]
    [./marker]
      type = ErrorFractionMarker
      indicator = indicator
      refine = 0.9
    [../]
  [../]
[]
