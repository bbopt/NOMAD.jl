const nomad_archive = joinpath(@__DIR__, "downloads", "NOMAD.zip")

builddir = @__DIR__

nomad_path = joinpath(builddir,"nomad.3.9.1")

if ispath(nomad_path)
	error("NOMAD.jl building error : nomad folder already exists, first remove it before building anew")
end

run(`unzip $nomad_archive -d $builddir`)

nomad_path = joinpath(builddir,"nomad.3.9.1")

ENV["NOMAD_HOME"] = nomad_path
