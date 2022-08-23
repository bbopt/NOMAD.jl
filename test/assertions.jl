@testset "creation of a Nomad problem : assertions" begin

    function simpletest(x)
        return (true, true, sum(x))
    end

    n = 0
    m = 1
    output_types = ["OBJ"]
    @test_throws(AssertionError, NomadProblem(n,m, output_types, simpletest))

    n = 1
    m = 0
    output_types = String[]
    @test_throws(AssertionError, NomadProblem(n, m, output_types, simpletest))

    n = 1
    m = 1
    output_types = ["OBJ", "PB"]
    @test_throws(AssertionError, NomadProblem(n, m, output_types, simpletest))

    n = 1
    m = 1
    output_types = ["WRONG"]
    @test_throws(AssertionError, solve(NomadProblem(n, m, output_types, simpletest), [1.0]))

    n = 1
    m = 1
    output_types = ["OBJ"]
    input_types = ["R", "B"]
    @test_throws(AssertionError, NomadProblem(n,m, output_types, simpletest,
                                              input_types = input_types))

    n = 1
    m = 1
    output_types = ["OBJ"]
    input_types = ["NOPE"]
    @test_throws(AssertionError, solve(NomadProblem(n,m, output_types, simpletest,
                                                    input_types = input_types),
                                       [1.0]))

    n = 1
    m = 1
    outputs_types = ["OBJ"]
    max_bb_eval = 1
    @test_throws(AssertionError, NomadProblem(n, m, output_types, simpletest,
                                              lower_bound=[3.0;4.0]))

    n = 1
    m = 1
    output_types = ["OBJ"]
    @test_throws(ErrorException, begin
                     p = NomadProblem(n, m, output_types, simpletest)
                     p.options.max_bb_eval = 0
                     solve(p, [1.0])
                 end)

    n = 1
    m = 1
    output_types = ["OBJ"]
    @test_throws(ErrorException, begin
                     p = NomadProblem(n, m, output_types, simpletest)
                     p.options.lh_search = (0,-1)
                     solve(p, [1.0])
                 end)

    n = 1
    m = 1
    output_types = ["OBJ"]
    @test_throws(AssertionError, NomadProblem(n, m, output_types, simpletest,
                                              upper_bound=[3.0;4.0]))

    n = 1
    m = 1
    outputs_types = ["OBJ"]
    @test_throws(AssertionError, NomadProblem(n,m, output_types, simpletest,
                                              initial_mesh_size=[1e-4;10]))

    n = 1
    m = 1
    output_types = ["OBJ"]
    max_bb_eval = 1
    p = NomadProblem(n, m, output_types, simpletest, upper_bound=[1.0])
    @test p.A === p.b === nothing
    @test p.min_mesh_size == zeros(1)
    @test isempty(p.initial_mesh_size)

    @test p.options.cache_size_max == typemax(Int64)
    @test p.options.display_degree == 2
    @test p.options.display_all_eval == false
    @test p.options.display_unsuccessful == false
    @test p.options.display_stats == String[]
    @test p.options.max_bb_eval == 20000
    @test p.options.sgtelib_model_max_eval == 1000
    @test p.options.eval_use_cache == true
    @test p.options.eval_queue_sort == "QUADRATIC_MODEL"
    @test p.options.lh_search == (0,0)
    @test p.options.quad_model_search == true
    @test p.options.sgtelib_model_search == false
    @test p.options.speculative_search == true
    @test p.options.speculative_search_max == 1
    @test p.options.nm_search == true
    @test p.options.nm_search_stop_on_success == false
    @test p.options.max_time === nothing

end
