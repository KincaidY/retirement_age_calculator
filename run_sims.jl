import CSV
import Statistics: mean, std
import StatsBase: percentile
import JSON
import StatsPlots: histogram

include("invest_sim.jl")

percent(str) = parse(Float64, str[1:end-1]) * 0.01
data = CSV.read("historical.csv")

data["sp_returns"] = percent.(data["sp_returns"])
data["three_month_tbill"] = percent.(data["three_month_tbill"])
data["us_tbond"] = percent.(data["us_tbond"])
data["baa_crop_bond"] = percent.(data["baa_crop_bond"])
data["inflation"] = percent.(data["inflation"])

if isfile("params.json")
    file = open("params.json")
    params = read(file, String)
    params = JSON.parse(params, dicttype=Dict{Symbol,Any})
    close(file)
    params[:post_tax_salary] = (1 - params[:tax_rate]) * params[:starting_salary]
    params[:historical_data] = data
    delete!(params,:starting_salary)
    delete!(params,:tax_rate)
else
    print("Starting salary: ")
    starting_salary = parse(Float64, readline(keep = false))
    print("Tax rate: ")
    tax_rate = parse(Float64, readline())
    post_tax_salary = starting_salary * (1 - tax_rate)
    println("Post tax starting salary is ", post_tax_salary)
    print("Post tax investment rate: ")
    investment_rate = parse(Float64, readline())
    print("Percent of portolio in bonds (or \"dynamic\"): ")
    bonds = readline()
    if bonds != "dynamic"
        bonds = parse(Float64, bonds)
    end
    print("Salary growth rate: ")
    salary_growth = parse(Float64, readline())
    print("Initial savings: ")
    initial_savings = parse(Float64, readline())
    print("Initial age: ")
    initial_age = parse(Float64, readline())
    print("Money needed annually in retirement: ")
    thresh = parse(Float64, readline())
    print("Proportion of capital to live on: ")
    withdraw = parse(Float64, readline())
    print("Age to stop saving? (enter 'None' if saving until retirement): ")
    stop_saving_age = parse(Float64, readline())
    if stop_savings_age == "None"
        stop_savings_age = 999
    end

    params = Dict(
        :post_tax_salary => post_tax_salary,
        :investment_rate => investment_rate,
        :salary_growth => salary_growth,
        :initial_savings => initial_savings,
        :initial_age => initial_age,
        :historical_data => data,
        :thresh => thresh,
        :withdraw => withdraw,
        :stop_savings_age => stop_savings_age,
        :bonds_percent => bonds
    )
end

print_params = copy(params)
delete!(print_params, :historical_data)
println("Running simulations with inputted historical returns and the following parameters: ")
println(print_params)
results = repeat_sim(;params...)
println("\nAverage retirement age: ", mean(results))
println("Standard deviation: ", std(results))
println("Max retirement age: ", maximum(results))
println("90th percentile retirement age: ", percentile(results, 95))
println("75th percentile retirement age: ", percentile(results, 75))
println("Median retirement age: ", percentile(results, 50))
println("Min retirement age: ", minimum(results))
print(length(results), " simulations run")
histogram(results,bins=length(results) ÷ 5, title="Financial Independence Age Distribution", legend=false)