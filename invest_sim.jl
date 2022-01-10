function returns(capital, age, year, historical_data, bonds_percent="dynamic")
    if bonds_percent == "dynamic"
        bonds_percent = age * .01
    end
    stocks_percent = 1 - bonds_percent
    stock_returns = historical_data[historical_data["year"] .== year,:]["sp_returns"] - historical_data[historical_data["year"] .== year,:]["inflation"]
    stock_returns = stocks_percent * stock_returns * capital
    bond_returns = bonds_percent * (capital * (1/3) * (historical_data[historical_data["year"] .== year,:]["three_month_tbill"] + historical_data[historical_data["year"] .== year,:]["us_tbond"] + historical_data[historical_data["year"] .== year,:]["baa_crop_bond"] - 3 * historical_data[historical_data["year"] .== year,:]["us_tbond"] + historical_data[historical_data["year"] .== year,:]["inflation"]))
    return (stock_returns + bond_returns)[1]
end

function invest_sim(
    post_tax_salary,
    investment_rate,
    salary_growth,
    initial_savings,
    initial_age,
    thresh,
    withdraw,
    start_year,
    stop_savings_age,
    historical_data,
    bonds_percent="dynamic"
    )
    
    capital = initial_savings
    year = start_year
    age = initial_age
    salary = post_tax_salary
    ret_sal = withdraw * capital
    
    while (ret_sal < thresh)
        capital += returns(capital, age, year, historical_data, bonds_percent)
        if age < stop_savings_age 
            capital += post_tax_salary * investment_rate
        end
        salary += salary * salary_growth
        age += 1
        year += 1
        ret_sal = withdraw * capital
        if year >= maximum(historical_data["year"])
            if ret_sal >= thresh
                return age
            else
                return false
            end
        end
    end
    return age
end

function repeat_sim(;
    post_tax_salary,
    investment_rate,
    salary_growth,
    initial_savings,
    initial_age,
    thresh,
    withdraw,
    stop_savings_age,
    historical_data,
    bonds_percent="dynamic"
    )

    ages = []
    age = true
    year = minimum(historical_data["year"])
    while age != false
        age = invest_sim(post_tax_salary, investment_rate, salary_growth, initial_savings, initial_age, thresh, withdraw, year, stop_savings_age, historical_data, bonds_percent)
        year += 1
        if age != false
            append!(ages,[age])
        end
    end
    return(ages)
end