module FundsAllocation

using DataFrames, XLSX, JuMP, CPLEX, Serialization

function read_expenses(filename::String)
    return DataFrame(XLSX.readtable(filename, "expenses")) |>
        df -> transform!(df, [Symbol("Transfer Amount"), Symbol("Balance After Transfer")] .=> ByRow(x -> 0); renamecols=false) |>
        df -> transform!(df, Symbol("CC: Level") => x -> parse.(Int8, x); renamecols=false) |>
        df -> transform!(df, [Symbol("CC: Overall"), Symbol("CC: Field/ HQ/ Global/ Reserve"), Symbol("CC: Region"), Symbol("CC: Subregion"), Symbol("CC: Country"), Symbol("CF: Cost Center")] .=> x -> convert.(String, x); renamecols=false) |>
        df -> transform!(df, [Symbol("EM: Pillar"), Symbol("EM: Situation"), Symbol("EM: Goal Category"), Symbol("EM: Goal"), Symbol("EM: Impact Area"), Symbol("EM: Outcome Area"), Symbol("EM: Marker")] .=> x -> coalesce.(x, "null"), renamecols=false) |>
        df -> transform!(df, [Symbol("Original Balance"), Symbol("Transfer Amount"), Symbol("Balance After Transfer")] .=> x -> convert.(Float64, x); renamecols=false) |>
        df -> select!(
            df,
            Symbol("CC: Level"),
            Symbol("CC: Overall"),
            Symbol("CC: Field/ HQ/ Global/ Reserve"),
            Symbol("CC: Region"),
            Symbol("CC: Subregion"),
            Symbol("CC: Country"),
            Symbol("CF: Cost Center"),
            Symbol("CF: Situation"),
            Symbol("CF: Goal Category"),
            Symbol("CF: Goal"),
            Symbol("CF: CD"),
            Symbol("CF: Site"),
            Symbol("EM: Pillar"),
            Symbol("EM: Situation"),
            Symbol("EM: Goal Category"),
            Symbol("EM: Goal"),
            Symbol("EM: Earmarking Pattern"),
            Symbol("EM: Earmarking Value"),
            Symbol("Account Type"),
            Symbol("Original Balance"),
            Symbol("Transfer Amount"),
            Symbol("Balance After Transfer"),
            Symbol("STEP"),
            Symbol("CF: Impact"),
            Symbol("CF: Outcome Output"),
            Symbol("CF: Marker"),
            Symbol("EM: Impact Area"),
            Symbol("EM: Outcome Area"),
            Symbol("EM: Marker")
        )
end

function filter_expenses(df_expenses::DataFrame)
    return df_expenses |>
        df -> subset(df, :STEP => x -> x .∉ Ref(["EXC", "ELIM"]); view=true) 
end

function read_funds(filename::String)
    return DataFrame(XLSX.readtable(filename, "funds")) |>
        df -> transform!(df, [Symbol("Transfer Amount"), Symbol("Balance After Transfer")] .=> ByRow(x -> 0); renamecols=false) |>
        df -> transform!(df, Symbol("CC: Level") => x -> parse.(Int8, x); renamecols=false) |>
        df -> transform!(df, [Symbol("CC: Overall"), Symbol("CC: Field/ HQ/ Global/ Reserve"), Symbol("CC: Region"), Symbol("CC: Subregion"), Symbol("CC: Country"), Symbol("CF: Cost Center")] .=> x -> convert.(String, x); renamecols=false) |>
        df -> transform!(df, [Symbol("EM: Pillar"), Symbol("EM: Situation"), Symbol("EM: Goal Category"), Symbol("EM: Goal"), Symbol("EM: Impact Area"), Symbol("EM: Outcome Area"), Symbol("EM: Marker")] .=> x -> coalesce.(x, "null"), renamecols=false) |>
        df -> transform!(df, [Symbol("Original Balance"), Symbol("Transfer Amount"), Symbol("Balance After Transfer")] .=> x -> convert.(Float64, x); renamecols=false) |>
        df -> select!(
            df,
            Symbol("CC: Level"),
            Symbol("CC: Overall"),
            Symbol("CC: Field/ HQ/ Global/ Reserve"),
            Symbol("CC: Region"),
            Symbol("CC: Subregion"),
            Symbol("CC: Country"),
            Symbol("CF: Cost Center"),
            Symbol("CF: Situation"),
            Symbol("CF: Goal Category"),
            Symbol("CF: Goal"),
            Symbol("CF: CD"),
            Symbol("CF: Site"),
            Symbol("EM: Pillar"),
            Symbol("EM: Situation"),
            Symbol("EM: Goal Category"),
            Symbol("EM: Goal"),
            Symbol("EM: Earmarking Pattern"),
            Symbol("EM: Earmarking Value"),
            Symbol("Account Type"),
            Symbol("Original Balance"),
            Symbol("Transfer Amount"),
            Symbol("Balance After Transfer"),
            Symbol("STEP1"),
            Symbol("STEP2"),
            Symbol("STEP3"),
            Symbol("STEP4"),
            Symbol("STEP5"),
            Symbol("STEP6"),
            Symbol("STEP7"),
            Symbol("STEP8"),
            Symbol("Spread evenly(Y/N)"),
            Symbol("DONOR CODE"),
            Symbol("CF: Impact"),
            Symbol("CF: Outcome Output"),
            Symbol("CF: Marker"),
            Symbol("EM: Impact Area"),
            Symbol("EM: Outcome Area"),
            Symbol("EM: Marker")
        )
end

function filter_funds(df_funds::DataFrame)
    return df_funds|>
        df -> subset(df, :STEP1 => x -> x .∉ Ref(["EXC", "ELIM"]); view=true)
end

function define_earmarking(sdf_expenses::SubDataFrame, sdf_funds::SubDataFrame)
    earmarking = zeros(Int8, nrow(sdf_expenses), nrow(sdf_funds))
    cols_funds = names(sdf_funds)
    for i in axes(sdf_funds, 1)
        row_funds = [sdf_funds[i, col] for col in cols_funds]
        level_funds = row_funds[1]
        earmarking_each_fund = repeat(1:1, nrow(sdf_expenses))
        for j in 1:level_funds
            earmarking_each_level = sdf_expenses[!, 1 + j] .== row_funds[1 + j]
            earmarking_each_fund = earmarking_each_fund .& earmarking_each_level
        end
        if (row_funds[13] != "9") && (row_funds[13] != "null")
            earmarking_pillar = sdf_expenses[!, 13] .== row_funds[13]
            earmarking_each_fund = earmarking_each_fund .& earmarking_pillar
        end
        if (row_funds[14] != "900") && (row_funds[14] != "901") && (row_funds[14] != "001") && (row_funds[14] != "null")
            earmarking_situation = sdf_expenses[!, 14] .== row_funds[14]
            if row_funds[14] == "008"
                earmarking_situation_exception_1 = (sdf_expenses[!, 14] .!= "900") .& (sdf_expenses[!, 14] .== "null")
                earmarking_situation = earmarking_situation .| earmarking_situation_exception_1
            end
            if row_funds[14] == "310"
                earmarking_situation_exception_2 = sdf_expenses[!, 14] .== "316"
                earmarking_situation = earmarking_situation .| earmarking_situation_exception_2
            end
            if row_funds[14] == "316"
                earmarking_situation_exception_3 = sdf_expenses[!, 14] .== "310"
                earmarking_situation = earmarking_situation .| earmarking_situation_exception_3
            end
            earmarking_each_fund = earmarking_each_fund .& earmarking_situation
        end
        if row_funds[15] != "null"
            earmarking_goal_category = sdf_expenses[!, 15] .== row_funds[15]
            earmarking_each_fund = earmarking_each_fund .& earmarking_goal_category
        end
        if row_funds[16] != "null"
            earmarking_goal = sdf_expenses[!, 16] .== row_funds[16]
            earmarking_each_fund = earmarking_each_fund .& earmarking_goal
        end
        if (row_funds[36] == "0") && (row_funds[36] != "null")
            earmarking_impact = sdf_expenses[!, 27] .== row_funds[36]
            earmarking_each_fund = earmarking_each_fund .& earmarking_impact
        end
        if row_funds[37] != "null"
            earmarking_outcome = sdf_expenses[!, 28] .== row_funds[37]
            earmarking_each_fund = earmarking_each_fund .& earmarking_outcome
        end
        if row_funds[38] != "null"
            earmarking_marker = sdf_expenses[!, 29] .== row_funds[38]
            earmarking_each_fund = earmarking_each_fund .& earmarking_marker
        end
        earmarking[:, i] = earmarking_each_fund
    end
    return earmarking
end

function generate_data(filename::String)
    println("reading expenses...")
    sdf_expenses = filter_expenses(read_expenses(filename))
    expenses = sdf_expenses[:, Symbol("Original Balance")]
    println("reading funds...")
    sdf_funds = filter_funds(read_funds(filename))
    funds = sdf_funds[:, Symbol("Original Balance")] .* -1
    println("defining earmarking...")
    earmarking = define_earmarking(sdf_expenses, sdf_funds)
    println("building matrix...")
    return [(earmarking[i, j], expenses[i], funds[j]) for i=axes(earmarking, 1), j=axes(earmarking, 2)]
end

function generate_model(data::Matrix{Tuple{Int8, Float64, Float64}})
    model = Model(CPLEX.Optimizer; add_bridges = false)
    set_string_names_on_creation(model, false)
    set_optimizer_attribute(model, "CPXPARAM_Threads", 4)
    E = axes(data, 1)
    F = axes(data, 2)
    println("adding variables...")
    @variable(model, 0 <= x[e = E, f = F] <= 1)
    for e in E
        for f in F
            if data[e, f][1] == 0
                fix(x[e, f], 0, force = true)
            end
        end
    end
    println("adding constraints...")
    @constraint(model, [f = F], sum(x[:, f]) <= 1)
    @constraint(model, [e = E], sum(x[e, f] * data[1, f][3] for f in F) <= data[e, 1][2])
    println("adding the objective...")
    @objective(model, Max, sum(data[1, f][3] * x[e, f] for e in E, f in F))
    return model
end

function customize_model(model::Model, filename::String)
    println("adding constraints on reserves...")
    x = model[:x]
    E = axes(x, 1)
    F = axes(x, 2)
    sdf_expenses = filter_expenses(read_expenses(filename))
    sdf_funds = filter_funds(read_funds(filename))
    funds_reserves = sdf_funds[!, "Account Type"] .== "Reserves"
    @constraint(model, sum(funds_reserves[f] * sdf_funds[f, "Original Balance"] * -1 * sum(x[:, f]) for f in F) <= 150000000)
    println("adding constraints on US exceptions...")
    exceptions_us = [
        "21120",
        "21121",
        "21122",
        "21126",
        "RUS",
        "52040",
        "52041",
        "52043",
        "CHN",
        "52361",
        "41042",
        "33040",
        "33041",
        "33042",
        "33043",
        "33044",
        "33045",
        "33054",
        "IRN"
    ]
    for e in E
        for f in F
            if (sdf_expenses[e, "CF: Cost Center"] in exceptions_us) && (sdf_funds[f, "DONOR CODE"] == "GUSA02")
                fix(x[e, f], 0, force = true)
            end
        end
    end
    println("adding constraints on US percentages...")
    expenses_countries = unique(sdf_expenses[!, "CC: Country"])
    funds_us = findall(sdf_funds[!, "DONOR CODE"] .== "GUSA02")
    for country in expenses_countries
        expenses_country = findall(sdf_expenses[!, "CC: Country"] .== country)
        @constraint(model, sum(x[e, f] * sdf_funds[f, "Original Balance"] * -1 for e in expenses_country, f in funds_us) <= sum(sdf_expenses[expenses_country, "Original Balance"] * 0.66))
    end
    return
end

function solve_model(filename::String)
    model = generate_model(generate_data(filename))
    customize_model(model, filename)
    println("running optimization...")
    optimize!(model)
    return model
end

function extract_coef(model::Model)
    println("extracting coefficients...")
    rows = size(model[:x])[1]
    cols = size(model[:x])[2]
    matrix_coef = similar(Array{Float64}, rows, cols)
    for i in 1:cols
        matrix_coef[:, i] = value.(model[:x][:, i])
    end
    return matrix_coef
end

function calculate_amounts(filename::String, matrix_coef::Matrix{Float64})
    println("calculating amounts...")
    df_funds = read_funds(filename)
    sdf_funds = filter_funds(df_funds)
    rows = size(matrix_coef)[1]
    cols = size(matrix_coef)[2]
    matrix_amounts = similar(Array{Float64}, rows, cols)
    for i in axes(matrix_coef, 2)
        matrix_amounts[:, i] = matrix_coef[:, i] .* sdf_funds[:, "Original Balance"][i]
    end
    return matrix_amounts
end

function update_expenses(filename::String, matrix_amounts::Matrix{Float64})
    println("updating expenses...")
    df_expenses = read_expenses(filename)
    sdf_expenses = filter_expenses(df_expenses)
    transfer_expenses = [sum(matrix_amounts[i, :]) for i in axes(matrix_amounts, 1)]
    transform!(sdf_expenses, Symbol("Transfer Amount") => x -> transfer_expenses; renamecols=false)
    transform!(df_expenses, [Symbol("Original Balance"), Symbol("Transfer Amount")] => ByRow(+) => Symbol("Balance After Transfer"))
    return df_expenses
end

function write_expenses(filename::String, df_expenses::DataFrame)
    println("writing expenses...")
    XLSX.openxlsx(filename, mode="rw") do xf
        sheet_expenses = xf["expenses"]
        for i in axes(df_expenses, 1)
            sheet_expenses[i + 1, 21] = df_expenses[i, 21]
            sheet_expenses[i + 1, 22] = df_expenses[i, 22]
        end
    end
    return
end

function update_funds(filename::String, matrix_amounts::Matrix{Float64})
    println("updating funds...")
    df_funds = read_funds(filename)
    sdf_funds = filter_funds(df_funds)
    transfer_funds = [sum(matrix_amounts[:, i]) * -1 for i in axes(matrix_amounts, 2)]
    transform!(sdf_funds, Symbol("Transfer Amount") => x -> transfer_funds; renamecols=false)
    transform!(df_funds, [Symbol("Original Balance"), Symbol("Transfer Amount")] => ByRow(+) => Symbol("Balance After Transfer"))
    return df_funds
end

function write_funds(filename::String, df_funds::DataFrame)
    println("writing funds...")
    XLSX.openxlsx(filename, mode="rw") do xf
        sheet_funds = xf["funds"]
        for i in axes(df_funds, 1)
            sheet_funds[i + 1, 21] = df_funds[i, 21]
            sheet_funds[i + 1, 22] = df_funds[i, 22]
        end
    end
    return
end

function generate_transfers(df_expenses::DataFrame, df_funds::DataFrame, matrix_amounts::Matrix{Float64})
    println("generating transfers...")
    sdf_expenses = filter_expenses(df_expenses)
    sdf_funds = filter_funds(df_funds)
    df_list = []
    for i in axes(matrix_amounts, 1)
        for j in axes(matrix_amounts, 2)
            if matrix_amounts[i, j] != 0
                df_to = sdf_expenses[[i], :] |>
                    df -> select(
                        df,
                        "CC: Level" => "To Level",
                        "CC: Overall" => "To Overall",
                        "CC: Field/ HQ/ Global/ Reserve" => "To Field/ HQ/ Global/ Reserve",
                        "CC: Region" => "To Region",
                        "CC: Subregion" => "To Subregion",
                        "CC: Country" => "To Country",
                        "CF: Cost Center" => "To Cost Center",
                        "CF: Situation" => "To Situation",
                        "CF: Impact" => "To Impact",
                        "CF: Outcome Output" => "To Outcome Output",
                        "CF: Goal Category" => "To Goal Category",
                        "CF: Goal" => "To Goal",
                        "CF: Marker" => "To Marker",
                        "CF: CD" => "To CD",
                        "CF: Site" => "To Site",
                        "Account Type" => "To Account Type",
                        "EM: Earmarking Pattern" => "To Earmarking pattern",
                        "EM: Earmarking Value" => "To Earmarking Value"
                    )
                df_from = sdf_funds[[j], :] |>
                    df -> select(
                        df,
                        "CC: Level" => "From Level",
                        "CC: Overall" => "From Overall",
                        "CC: Field/ HQ/ Global/ Reserve" => "From Field/ HQ/ Global/ Reserve",
                        "CC: Region" => "From Region",
                        "CC: Subregion" => "From Subregion",
                        "CC: Country" => "From Country",
                        "CF: Cost Center" => "From Cost Center",
                        "CF: Situation" => "From Situation",
                        "CF: Impact" => "From Impact",
                        "CF: Outcome Output" => "From Outcome Output",
                        "CF: Goal Category" => "From Goal Category",
                        "CF: Goal" => "From Goal",
                        "CF: Marker" => "From Marker",
                        "CF: CD" => "From CD",
                        "CF: Site" => "From Site",
                        "Account Type" => "From Account Type",
                        "EM: Earmarking Pattern" => "From Earmarking pattern",
                        "EM: Earmarking Value" => "From Earmarking Value"
                    )
                df_concat = hcat(df_to, df_from) |>
                    df -> insertcols!(df, "From Earmarking Value", "Amount USD" => matrix_amounts[i, j] * -1, after=true)
                push!(df_list, df_concat)
            end
        end
    end
    df_transfers = vcat(df_list...) |>
        df -> insertcols!(df, 1, "Allocation Step NumberFUND" => nothing) |>
        df -> insertcols!(df, 1, "Allocation Step NumberEXPENSE" => nothing) |>
        df -> insertcols!(df, 1, "Transfer ID" => 1:nrow(df))
    return df_transfers
end

function write_transfers(filename::String, df_transfers::DataFrame)
    println("writing transfers...")
    XLSX.openxlsx(filename, mode="rw") do xf
        sheet_transfers = xf["transfers"]
        cols_transfers = names(df_transfers)
        sheet_transfers[1, :] = cols_transfers
        for i in axes(df_transfers, 1)
            row_transfers = [df_transfers[i, col] for col in cols_transfers]
            sheet_transfers[i + 1, :] = row_transfers
        end
    end
    return
end

function write_result(filename::String, model::Model)
    matrix_coef = extract_coef(model)
    matrix_amounts = calculate_amounts(filename, matrix_coef)
    df_expenses = update_expenses(filename, matrix_amounts)
    write_expenses(filename, df_expenses)
    df_funds = update_funds(filename, matrix_amounts)
    write_funds(filename, df_funds)
    df_transfers = generate_transfers(df_expenses, df_funds, matrix_amounts)
    write_transfers(filename, df_transfers)
end

function main(filename::String)
    model = solve_model(filename)
    write_result(filename, model)
    return model
end

end
