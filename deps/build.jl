const nomad_archive = joinpath(@__DIR__, "downloads", "NOMAD.zip")

builddir = @__DIR__

nomad_path = joinpath(builddir,"nomad.3.9.1")

if isdir(nomad_path)
    rm(nomad_path, recursive=true)
end

run(`unzip $nomad_archive -d $builddir`)

nomad_path = joinpath(builddir,"nomad.3.9.1")

ENV["NOMAD_HOME"] = nomad_path

cd(nomad_path)

run(`./configure`)

run(`make`)

cd(joinpath(nomad_path,"src"))

run(`make all`)
