builddir = @__DIR__
nomad_path = joinpath(builddir,"nomad.3.9.1")

if ispath(nomad_path)
	error("NOMAD.jl building error : nomad folder already exists, first remove it before building anew")
end

if Sys.iswindows()
	error("NOMAD.jl error : The package is not compatible with Windows operating systems")
else
	# We will have NOMAD compiled on your machine
	try
		zipnomad = joinpath(builddir,"downloads/NOMAD.zip")
		run(`unzip $zipnomad -d $builddir`)
		ENV["NOMAD_HOME"] = nomad_path
		cd(nomad_path)
		run(`./configure`)
		run(`make`)
	catch e
		rm(nomad_path; recursive=true, force=true)
		@warn "NOMAD could not be compiled automatically, try ./configure and make extracted files from NOMAD.jl/deps/downloads/NOMAD.zip"
		throw(e)
	end
end
