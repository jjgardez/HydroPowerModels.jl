function simulate_model(m::SDDPModel, N::Int; asynchronous::Bool = true)
    solution = Dict()
    solution["simulations"] = Array{Dict}(N)
    tic()
    if asynchronous
        wp = CachingPool(workers())
        let m = m
            solution["simulations"] .= pmap(wp, (i) -> randomsimulation(m), 1:N)
        end
    else
        solution["simulations"] .= map(i -> randomsimulation(m), 1:N)
    end
    solution["solve_time"] = toc()
    solution["solver"] = string(typeof(m.stages[1].subproblems[1].solver))
    solution["machine"] = Dict(
        "cpu" => Sys.cpu_info()[1].model,
        "memory" => string(Sys.total_memory()/2^30, " Gb")
    )

    # add original data dict
    solution["data"] = m.ext[:data]
    
    return solution
end

function randomsimulation(m::SDDPModel)
    store = SDDP.newsolutionstore(Symbol[])
    obj = SDDP.forwardpass!(m, SDDP.Settings(),store)
    store[:objective] = obj
    solution = build_solution_single_simulation(m)
    for (key,value) in  store
        solution[string(key)] = value
    end
    return solution
end