
# This file includes modified source code from https://github.com/odow/SDDP.jl
# as at d90faae19c90f1fa03636ebe1cee92b083c355c2

#  Copyright 2017, Oscar Dowson and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.
#############################################################################

function simulate(hydromodel::HydroPowerModel,number_replications::Int = 1;kwargs...)
    solution = Dict{Symbol, Any}()
    
    start_time = time()
    solution[:simulations] = SDDP.simulate( hydromodel.policygraph, 
                                            number_replications,
                                            custom_recorders = Dict{Symbol, Function}(
                                                :powersystem => build_sol_powermodels,
                                                :reservoirs => build_sol_reservoirs,
                                                :objective => objective_value
                                            ))
    solution[:solve_time] = end_time = time() - start_time

    solution[:params] = hydromodel.params
    solution[:machine] = Dict(
        :cpu => Sys.cpu_info()[1].model,
        :memory => string(Sys.total_memory()/2^30, " Gb")
    )

    # add original data dict
    solution[:data] = hydromodel.alldata

    return solution

end

"PowerModels solution build "
function build_sol_powermodels(sp::JuMP.Model)
    solve_time = MOI.get(sp, MOI.SolveTime())
    status = JuMP.termination_status(sp)
    built_sol = PowerModels.build_solution(sp.ext[:pm],status,solve_time,
        solution_builder = PowerModels.get_solution)
end

"Reservoir solution build "
function build_sol_reservoirs(sp::JuMP.Model)
    store = Dict{Symbol, Any}(
            :reservoir => JuMP.value.(sp[:reservoir]),
            :outflow => JuMP.value.(sp[:outflow]),
            :spill => JuMP.value.(sp[:spill])
        )
    return store
end
