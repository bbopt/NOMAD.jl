#Define aliases for C++ types

if Sys.islinux()

    CvectorString = Cxx.CxxCore.CppValue{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::vector")},Tuple{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::basic_string")},Tuple{UInt8,Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::char_traits")},Tuple{UInt8}},(false, false, false)},Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::allocator")},Tuple{UInt8}},(false, false, false)}}},(false, false, false)},Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::allocator")},Tuple{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::basic_string")},Tuple{UInt8,Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::char_traits")},Tuple{UInt8}},(false, false, false)},Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::allocator")},Tuple{UInt8}},(false, false, false)}}},(false, false, false)}}},(false, false, false)}}},(false, false, false)},24}

elseif Sys.isapple()

    CvectorString = Cxx.CxxCore.CppValue{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::__1::vector")},Tuple{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::__1::basic_string")},Tuple{UInt8,Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::__1::char_traits")},Tuple{UInt8}},(false, false, false)},Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::__1::allocator")},Tuple{UInt8}},(false, false, false)}}},(false, false, false)},Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::__1::allocator")},Tuple{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::__1::basic_string")},Tuple{UInt8,Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::__1::char_traits")},Tuple{UInt8}},(false, false, false)},Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::__1::allocator")},Tuple{UInt8}},(false, false, false)}}},(false, false, false)}}},(false, false, false)}}},(false, false, false)},24}

end

Cstring = Ptr{UInt8}

CnomadPoint = Cxx.CxxCore.CppValue{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{Symbol("NOMAD_MAJOR_VER_MINOR_VER_REV_VER::Point")},(false, false, false)},24}

Cresults = Cxx.CxxCore.CppValue{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{:Cresult},(false, false, false)},552}
