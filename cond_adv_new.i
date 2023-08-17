[Mesh]
  type = FileMesh
  file = first_mesh.e
[]

[GlobalParams]
  PorousFlowDictator = dictator
  gravity = '-9.8 0 0'
[]

[Variables]
  [temp]
    scaling = 1E-10
  []
  [pp]
  []
[]

[Functions]
  [pres_func]
    type = ParsedFunction
    expression = '(-z) * rho * g'
    symbol_names =  'rho g'
    symbol_values = '1000 9.81'
  []
  [temp_func]
      type = ParsedFunction
      expression = 't_surf + (-z) * 0.025'
      symbol_names =  't_surf'
      symbol_values = '300'
  []
  [massrate_inj_pp]
    type = ParsedFunction
    expression = '-1'
  []
  [massrate_pro_pp]
    type = ParsedFunction
    expression = '1'
  []
  [inject_hot]
    type = ParsedFunction
    expression = 'if(t >= 0 & t < 5, -1,
    if(t >= 10 & t < 15, -1, 0))'
  []
  [produce_cold]
    type = ParsedFunction
    expression = 'if(t >= 0 & t < 5, 1,
    if(t >= 10 & t < 15, 1, 0))'
  []
  [produce_hot]
    type = ParsedFunction
    expression = 'if(t >= 5 & t < 10, 1,
    if(t >= 15 & t < 20, 1, 0))'
  []
  [inject_cold]
    type = ParsedFunction
    expression = 'if(t >= 5 & t < 10, -1,
    if(t >= 15 & t < 20, -1, 0))'
  []
[]

[ICs]
  [pressure_ic]
    type = FunctionIC
    variable = pp
    function = pres_func
  []
  [temperature_ic]
    type = FunctionIC
    variable = temp
    function = temp_func
  []
[]

[BCs]
  [./top_pres]
    type = FunctionDirichletBC
    variable = pp
    function = pres_func
    boundary = 'top_side'
  [../]
  [./top_temp]
    type = FunctionDirichletBC
    variable = temp
    function = temp_func
    boundary = 'top_side bottom_side'
  [../]
  [./bottom_temp]
    type = FunctionDirichletBC
    variable = temp
    function = temp_func
    boundary = 'bottom_side'
  [../]
  [inject_heat]
    type = DirichletBC
    variable = temp
    boundary = 'hot_area'
    value = 350
  []
  [inject_fluid_hot]
    type = PorousFlowSink
    variable = pp
    boundary = 'hot_area'
    flux_function = massrate_inj_pp
  []
  [produce_heat]
    type = PorousFlowSink
    variable = temp
    boundary = 'hot_area'
    flux_function = massrate_pro_pp
    fluid_phase = 0
    use_enthalpy = true
    # save_in = heat_flux_out
  []
  [produce_fluid_hot]
    type = PorousFlowSink
    variable = pp
    boundary = 'hot_area'
    flux_function = massrate_pro_pp
  []
[]

[Controls]
  [hot_inject_on]
    type = ConditionalFunctionEnableControl
    enable_objects = 'BCs::inject_heat BCs::inject_fluid_hot'
    conditional_function = inject_hot
    implicit = false
    execute_on = 'initial timestep_begin'
  []
  [hot_produce_on]
    type = ConditionalFunctionEnableControl
    enable_objects = 'BCs::produce_heat BCs::produce_fluid_hot'
    conditional_function = produce_hot
    implicit = false
    execute_on = 'initial timestep_begin'
  []
[]

[Kernels]
  [mass_dot]
    type = PorousFlowMassTimeDerivative
    fluid_component = 0
    variable = pp
  []
  [advection]
    type = PorousFlowFullySaturatedDarcyBase
    variable = pp
  []
  [energy_dot]
    type = PorousFlowEnergyTimeDerivative
    variable = temp
  []
  [convection]
    type = PorousFlowFullySaturatedHeatAdvection
    variable = temp
  []
  [heat_conduction]
    type = PorousFlowHeatConduction
    variable = temp
  []
[]

[UserObjects]
  [dictator]
    type = PorousFlowDictator
    porous_flow_vars = 'temp pp'
    number_fluid_phases = 1
    number_fluid_components = 1
  []
  [produced_mass_water]
    type = PorousFlowSumQuantity
  []
  [produced_heat]
    type = PorousFlowSumQuantity
  []
[]

[FluidProperties]
  [simple_fluid]
    type = SimpleFluidProperties
    bulk_modulus = 2E9
    viscosity = 1.0e-3
    density0 = 1000.0
    thermal_expansion = 0.0
  []
[]

[Materials]
  [temperature]
    type = PorousFlowTemperature
    temperature = temp
  []
  [PS]
    type = PorousFlow1PhaseFullySaturated
    porepressure = pp
  []
  [massfrac]
    type = PorousFlowMassFraction
  []
  [simple_fluid]
    type = PorousFlowSingleComponentFluid
    fp = simple_fluid
    phase = 0
  []
  [fp_mat]
    type = FluidPropertiesMaterialPT
    pressure = pp
    temperature = temp
    fp = simple_fluid
  []
  [porosity_cap]
    type = PorousFlowPorosityConst
    porosity = 0.05
    block = 'cap_TETRA cap_PYRAMID5'
  []
  [porosity_res]
    type = PorousFlowPorosityConst
    porosity = 0.2
    block = 'res_TETRA res_PYRAMID5'
  []
  [porosity_bh]
    type = PorousFlowPorosityConst
    porosity = 1
    block = 'hot_leg_vol cold_leg_vol'
  []
  [rock_internal_energy]
    type = PorousFlowMatrixInternalEnergy
    density = 2500.0
    specific_heat_capacity = 1200.0
    block = 'cap_TETRA cap_PYRAMID5 res_TETRA res_PYRAMID5'
  []
  [bh_internal_energy]
    type = PorousFlowMatrixInternalEnergy
    density = 1000.0
    specific_heat_capacity = 4186.0
    block = 'hot_leg_vol cold_leg_vol'
  []
  [permeability_cap]
    type = PorousFlowPermeabilityConst
    permeability = '1E-17 0 0   0 1E-17 0   0 0 1E-17'
    block = 'cap_TETRA cap_PYRAMID5'
  []
  [permeability_res]
    type = PorousFlowPermeabilityConst
    permeability = '1E-14 0 0   0 1E-14 0   0 0 1E-14'
    block = 'res_TETRA res_PYRAMID5'
  []
  [permeability_bh]
    type = PorousFlowPermeabilityConst
    permeability = '1E-8 0 0   0 1E-8 0   0 0 1E-8'
    block = 'hot_leg_vol cold_leg_vol'
  []
  [thermal_conductivity]
    type = PorousFlowThermalConductivityIdeal
    dry_thermal_conductivity = '2 0 0  0 2 0  0 0 2'
    block = 'cap_TETRA cap_PYRAMID5 res_TETRA res_PYRAMID5'
  []
  [thermal_conductivity_bh]
    type = PorousFlowThermalConductivityIdeal
    dry_thermal_conductivity = '0.6 0 0  0 0.6 0  0 0 0.6'
    block = 'hot_leg_vol cold_leg_vol'
  []
  

[]

[Preconditioning]
  active = basic
  [basic]
    type = SMP
    full = true
    petsc_options = '-ksp_diagonal_scale -ksp_diagonal_scale_fix'
    petsc_options_iname = '-pc_type -sub_pc_type -sub_pc_factor_shift_type -pc_asm_overlap'
    petsc_options_value = ' asm      lu           NONZERO                   2'
  []
  [preferred]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
    petsc_options_value = ' lu       mumps'
  []
[]

[Executioner]
  type = Transient
  solve_type = Newton
  dt = 1
  end_time = 20
[]

[Outputs]
  exodus = true
[]