COMPILER = g++
COMPILER_MPI = mpic++
ALL = nompi
UNAME := $(shell uname)

ifndef VARIANT
VARIANT             = release
endif

ifndef NOMAD_HOME
$(info NOMAD_HOME is not yet defined!)
endif


TOP                 = $(shell pwd)/..
BUILD_DIR           = $(TOP)/builds/$(VARIANT)
SRC_DIR             = $(TOP)/src
BIN_DIR             = $(BUILD_DIR)/bin
EXE                 = $(BIN_DIR)/nomad
EXE_MPI             = $(BIN_DIR)/nomad.MPI

LIB_DIR             = $(BUILD_DIR)/lib
LIB_NAME            = libnomad.so
LIB_NAME_MPI        = libnomad.MPI.so

LIB                 = $(LIB_DIR)/$(LIB_NAME)
LIB_MPI             = $(LIB_DIR)/$(LIB_NAME_MPI)

LIB_CURRENT_VERSION = 3.9.1

SGTELIB_HOME        = $(TOP)/ext/sgtelib
LIBSGTELIB_NAME     = libsgtelib.so

OBJ_DIR_NO_MPI      = $(BUILD_DIR)/obj/ObjsNoMPI 
OBJ_DIR_MPI         = $(BUILD_DIR)/obj/ObjsMPI
OBJ_DIR = 

ifeq ($(VARIANT), release)
CXXFLAGS            = -O2 -D_GLIBCXX_USE_CXX11_ABI=0 -Wall -Wno-unused-variable -fpic
else
CXXFLAGS            = -g -D_GLIBCXX_USE_CXX11_ABI=0 -Wall -Wno-unused-variable -fpic
endif
CXXFLAGS_LIBS          =
CXXFLAGS_EXE           =           
ifeq ($(UNAME), Darwin)
CXXFLAGS_LIBS          = -current_version $(LIB_CURRENT_VERSION) -compatibility_version $(LIB_CURRENT_VERSION) -install_name $(LIB_NAME) -headerpad_max_install_names
CXXFLAGS_LIBS_MPI      = -current_version $(LIB_CURRENT_VERSION) -compatibility_version $(LIB_CURRENT_VERSION) -install_name $(LIB_NAME_MPI) -headerpad_max_install_names
CXXFLAGS_EXE          += -headerpad_max_install_names
endif
ifeq ($(UNAME), Linux)
CXXFLAGS_LIBS         += -Wl,-soname,'$(LIB_NAME)' -Wl,-rpath-link,'.' -Wl,-rpath,'$$ORIGIN'
CXXFLAGS_LIBS_MPI     += -Wl,-soname,'$(LIB_NAME_MPI)' -Wl,-rpath-link,'.' -Wl,-rpath,'$$ORIGIN'
CXXFLAGS_EXE          += -Wl,-rpath-link,'$(LIB_DIR)' -Wl,-rpath,'$$ORIGIN/../lib'
endif

CXXFLAGS_MPI           = $(CXXFLAGS) -DUSE_MPI # -DMPICH_IGNORE_CXX_SEEK -DMPICH_SKIP_MPICXX

LDLIBS_EXE             = -lm -lnomad 
LDLIBS_LIBS            = -lm -lsgtelib
LDLIBS_EXE_MPI         = -lm -lnomad.MPI -lmpi
LDLIBS_LIBS_MPI        = $(LDLIBS_LIBS) -lmpi

LDFLAGS                = -L$(LIB_DIR)

INCLUDE                = -I. -I$(SGTELIB_HOME)/src

COMPILE                = 
COMPILE_NO_MPI         = $(COMPILER) $(CXXFLAGS) $(INCLUDE) -c
COMPILE_MPI            = $(COMPILER_MPI) $(CXXFLAGS_MPI) $(INCLUDE) -c

OBJS_LIB               = Algo_Parameters.o Barrier.o Cache.o Cache_File_Point.o Cache_Point.o \
                         Cache_Search.o Clock.o Direction.o Directions.o Display.o \
                         Double.o Eval_Point.o Evaluator.o Evaluator_Control.o \
                         Extended_Poll.o L_Curve.o LH_Search.o Mads.o \
                         OrthogonalMesh.o Model_Sorted_Point.o Model_Stats.o Multi_Obj_Evaluator.o \
                         NelderMead_Search.o NelderMead_Simplex_Eval_Point.o \
                         Parameters.o Parameter_Entries.o Parameter_Entry.o \
                         Pareto_Front.o Pareto_Point.o Phase_One_Evaluator.o \
                         Phase_One_Search.o Point.o Priority_Eval_Point.o Quad_Model.o \
                         Quad_Model_Evaluator.o Quad_Model_Search.o Random_Pickup.o \
                         RNG.o Sgtelib_Model_Evaluator.o Sgtelib_Model_Search.o Sgtelib_Model_Manager.o \
                         Signature.o Slave.o Speculative_Search.o Stats.o \
                         SMesh.o TrendMatrix_Line_Search.o GMesh.o XMesh.o \
                         utils.o Variable_Group.o VNS_Search.o 
                         
OBJ_MAIN               = nomad.o 

OBJS_LIB              := $(addprefix $(OBJ_DIR)/,$(OBJS_LIB))
OBJ_MAIN              := $(addprefix $(OBJ_DIR)/,$(OBJ_MAIN))


define DisplayCommand
	@if $(1) ; then echo " ---> $@ OK" ; else echo " compilation failed for $@" ; fi
endef
define DisplayCommand0
	@if $(1) ; then echo " ---> OK" ; else echo " command FAILED" ; fi
endef
define DisplayCommand2
	@if $(1) ; then echo " ---> $2 OK" ; else echo " command $2 FAILED" ; fi
endef

define Mess
	@echo $1 $2
endef

all: $(ALL)

nompi:
	@echo
	@mkdir -p $(OBJ_DIR_NO_MPI)
	@echo " ===== Creating the SGTELIB shared objects library and executables ===== "
	@$(MAKE) -C $(SGTELIB_HOME)/src SHORT_DISPLAY='y' all
	@echo " ===== Create links to $(LIBSGTELIB_NAME) ====="
	@mkdir -p $(LIB_DIR)
	@mkdir -p $(TOP)/lib
	@mkdir -p $(TOP)/bin
	$(call DisplayCommand2,ln -fs $(SGTELIB_HOME)/lib/$(LIBSGTELIB_NAME) $(LIB_DIR)/$(LIBSGTELIB_NAME),"link into NOMAD build dir")
	$(call DisplayCommand2,ln -fs $(SGTELIB_HOME)/lib/$(LIBSGTELIB_NAME) $(TOP)/lib/$(LIBSGTELIB_NAME),"link into NOMAD lib dir")
	@echo
	@mkdir -p $(BIN_DIR)
	@$(MAKE) OBJ_DIR=$(OBJ_DIR_NO_MPI) COMPILE='$(COMPILE_NO_MPI)' $(LIB) $(EXE)
	
mpi:
	@mkdir -p $(OBJ_DIR_MPI)
	@echo " ===== Creating the SGTELIB shared objects library ===== "
	@$(MAKE) -C $(SGTELIB_HOME)/src SHORT_DISPLAY='y' all
	@echo " ===== Create links to $(LIBSGTELIB_NAME) ====="
	@mkdir -p $(LIB_DIR)
	@mkdir -p $(TOP)/lib
	@mkdir -p $(TOP)/bin
	$(call DisplayCommand2,ln -fs $(SGTELIB_HOME)/lib/$(LIBSGTELIB_NAME) $(LIB_DIR)/$(LIBSGTELIB_NAME),"link into NOMAD build dir")
	$(call DisplayCommand2,ln -fs $(SGTELIB_HOME)/lib/$(LIBSGTELIB_NAME) $(TOP)/lib/$(LIBSGTELIB_NAME),"link into NOMAD lib dir")
	@echo
	@mkdir -p $(BIN_DIR)
	@$(MAKE) OBJ_DIR=$(OBJ_DIR_MPI) COMPILE='$(COMPILE_MPI)' $(LIB_MPI) $(EXE_MPI)

installAllNomad: all mpi
	@echo
	@echo " ===== cleaning obj files and build directories ===== "
	$(call DisplayCommand0,rm -rf $(OBJ_DIR_NO_MPI) $(OBJ_DIR_MPI))
	@echo
	
clean:
	@echo
	@echo " ===== Cleaning obj files and build directories ===== "
	@echo " == Cleaning SGTELIB =="
	@$(MAKE) -C $(SGTELIB_HOME)/src SHORT_DISPLAY='y' clean
	@echo " == Cleaning NOMAD obj files =="  
	$(call DisplayCommand0,rm -rf $(OBJ_DIR_NO_MPI) $(OBJ_DIR_MPI))
	@echo
	
del: clean
	@echo
	@echo " ===== Deleting files ===== "
	@echo " == del SGTELIB =="
	@$(MAKE) -C $(SGTELIB_HOME)/src SHORT_DISPLAY='y' del
	@echo " == del NOMAD == " 
	$(call DisplayCommand2,rm -f core *~,"cleaning trash files ")
	$(call DisplayCommand2,rm -f $(EXE) $(EXE_MPI),"cleaning exe file")
	$(call DisplayCommand2,rm -f $(LIB) $(LIB_MPI),"cleaning lib files")
	$(call DisplayCommand2,rm -f $(TOP)/lib/$(LIB_NAME) $(TOP)/lib/$(LIB_NAME_MPI) $(TOP)/lib/$(LIBSGTELIB_NAME) $(LIB) $(LIB_MPI) $(LIB_DIR)/$(LIBSGTELIB_NAME),"cleaning symbolic links")	
	@echo

$(EXE): $(LIB) mess $(OBJ_MAIN)
	@echo
	@echo " ===== Creating the NOMAD executable $(VARIANT) version (no MPI) ===== "
	@mkdir -p $(BIN_DIR)
	$(call DisplayCommand2,rm -f $(TOP)/bin/nomad,"cleaning link to executables")
	$(call DisplayCommand,$(COMPILER) -o $(EXE) $(OBJ_MAIN) $(LDLIBS_EXE) $(LDFLAGS) $(CXXFLAGS_EXE))
ifeq ($(UNAME), Darwin)
	@install_name_tool -change $(LIB_NAME) @loader_path/../lib/$(LIB_NAME) $(EXE)
endif
	$(call DisplayCommand2,ln -s $(EXE) $(TOP)/bin,"creating symbolic link to executable")
	@echo

.PHONY:mess
mess: 
	@echo
	@echo " ===== Compiling Nomad objects ===== "

$(LIB): mess $(OBJS_LIB) $(OBJ_MAIN)
	@mkdir -p $(LIB_DIR)
	@echo 	
	@echo " ===== Creating the NOMAD shared objects library (no MPI) ===== " 
	$(call DisplayCommand2,rm -f $(TOP)/lib/$(LIB_NAME),"cleaning link to lib files")
	$(call DisplayCommand,$(COMPILER) -shared -o $(LIB) $(OBJS_LIB) $(LDLIBS_LIBS) $(LDFLAGS) $(CXXFLAGS_LIBS))
ifeq ($(UNAME), Darwin)
	@install_name_tool -change $(LIBSGTELIB_NAME) @loader_path/$(LIBSGTELIB_NAME) $(LIB)
endif
	$(call DisplayCommand2,ln -s $(LIB) $(TOP)/lib/$(LIB_NAME),"creating symbolic link to lib file")
	@echo
 
$(EXE_MPI): $(LIB_MPI) $(OBJ_MAIN)
	@echo
	@echo " ===== Creating the NOMAD executable $(VARIANT) version (MPI) ===== "
	@mkdir -p $(BIN_DIR)
	$(call DisplayCommand2,rm -f $(TOP)/bin/nomad.MPI,"cleaning link to executables")
	$(call DisplayCommand,$(COMPILER_MPI) -o $(EXE_MPI) $(OBJ_MAIN) $(LDLIBS_EXE_MPI) $(LDFLAGS) $(CXXFLAGS_EXE))
ifeq ($(UNAME), Darwin)
	@install_name_tool -change $(LIB_NAME_MPI) @loader_path/../lib/$(LIB_NAME_MPI) $(EXE_MPI)
endif
	$(call DisplayCommand2,ln -s $(EXE_MPI) $(TOP)/bin,"creating symbolic link to executable")
	@echo


$(LIB_MPI): mess $(OBJS_LIB)
	@mkdir -p $(LIB_DIR)
	@echo
	@echo " ===== Creating the NOMAD shared objects library (MPI) ===== "
	$(call DisplayCommand2,rm -f $(TOP)/lib/$(LIB_NAME_MPI),"cleaning link to lib files")
	$(call DisplayCommand,$(COMPILER_MPI) -shared -o $(LIB_MPI) $(OBJS_LIB) $(LDLIBS_LIBS_MPI) $(LDFLAGS) $(CXXFLAGS_LIBS_MPI))
ifeq ($(UNAME), Darwin)
	@install_name_tool -change $(LIBSGTELIB_NAME) @loader_path/$(LIBSGTELIB_NAME) $(LIB_MPI)
endif
	$(call DisplayCommand2,ln -s $(LIB_MPI) $(TOP)/lib/$(LIB_NAME_MPI),"creating symbolic link to lib files")
	@echo

	
#$(OBJ_DIR)/%.o: %.cpp %.hpp
#	$(COMPILE) $< -o $@

$(OBJ_DIR)/Algo_Parameters.o: Algo_Parameters.cpp Algo_Parameters.hpp
	$(call DisplayCommand,$(COMPILE) Algo_Parameters.cpp -o $@)
	
$(OBJ_DIR)/Barrier.o: Barrier.cpp Barrier.hpp Filter_Point.hpp Set_Element.hpp
	$(call DisplayCommand,$(COMPILE) Barrier.cpp -o $@)

$(OBJ_DIR)/Cache.o: Cache.cpp Cache.hpp
	$(call DisplayCommand,$(COMPILE) Cache.cpp -o $@)

$(OBJ_DIR)/Cache_File_Point.o: Cache_File_Point.cpp Cache_File_Point.hpp \
                    Eval_Point.cpp Eval_Point.hpp Uncopyable.hpp
	$(call DisplayCommand,$(COMPILE) Cache_File_Point.cpp -o $@)

$(OBJ_DIR)/Cache_Point.o: Cache_Point.cpp Cache_Point.hpp
	$(call DisplayCommand,$(COMPILE) Cache_Point.cpp -o $@)

$(OBJ_DIR)/Cache_Search.o: Cache_Search.cpp Cache_Search.hpp Search.hpp
	$(call DisplayCommand,$(COMPILE) Cache_Search.cpp -o $@)

$(OBJ_DIR)/Clock.o: Clock.cpp Clock.hpp
	$(call DisplayCommand,$(COMPILE) Clock.cpp -o $@)

$(OBJ_DIR)/Direction.o: Direction.cpp Direction.hpp Point.hpp
	$(call DisplayCommand,$(COMPILE) Direction.cpp -o $@)

$(OBJ_DIR)/Directions.o: Directions.cpp Directions.hpp OrthogonalMesh.hpp Random_Pickup.hpp RNG.hpp
	$(call DisplayCommand,$(COMPILE) Directions.cpp -o $@)

$(OBJ_DIR)/Display.o: Display.cpp Display.hpp utils.hpp
	$(call DisplayCommand,$(COMPILE) Display.cpp -o $@)

$(OBJ_DIR)/Double.o: Double.cpp Double.hpp Exception.hpp Display.hpp
	$(call DisplayCommand,$(COMPILE) Double.cpp -o $@)

$(OBJ_DIR)/Eval_Point.o: Eval_Point.cpp Eval_Point.hpp Parameters.hpp Cache_File_Point.hpp \
              Set_Element.hpp
	$(call DisplayCommand,$(COMPILE) Eval_Point.cpp -o $@)

$(OBJ_DIR)/Evaluator.o: Evaluator.cpp Evaluator.hpp Priority_Eval_Point.hpp Stats.hpp
	$(call DisplayCommand,$(COMPILE) Evaluator.cpp -o $@)

$(OBJ_DIR)/Evaluator_Control.o: Evaluator_Control.cpp Evaluator_Control.hpp \
            Barrier.hpp Pareto_Front.hpp Slave.hpp Quad_Model.hpp        
	$(call DisplayCommand,$(COMPILE) Evaluator_Control.cpp -o $@)

$(OBJ_DIR)/Extended_Poll.o: Extended_Poll.cpp Extended_Poll.hpp Signature_Element.hpp \
                 Set_Element.hpp Mads.hpp
	$(call DisplayCommand,$(COMPILE) Extended_Poll.cpp -o $@)

$(OBJ_DIR)/L_Curve.o: L_Curve.cpp L_Curve.hpp Double.hpp Uncopyable.hpp
	$(call DisplayCommand,$(COMPILE) L_Curve.cpp -o $@)

$(OBJ_DIR)/LH_Search.o: LH_Search.cpp LH_Search.hpp Search.hpp Mads.hpp RNG.hpp Evaluator_Control.hpp
	$(call DisplayCommand,$(COMPILE) LH_Search.cpp -o $@)

$(OBJ_DIR)/Mads.o: Mads.cpp Mads.hpp Evaluator_Control.hpp L_Curve.hpp \
        LH_Search.hpp LH_Search.cpp \
        Speculative_Search.cpp Speculative_Search.hpp \
        Extended_Poll.cpp Extended_Poll.hpp \
        VNS_Search.hpp VNS_Search.cpp \
        Quad_Model_Search.hpp Quad_Model_Search.cpp \
        Cache_Search.hpp Cache_Search.cpp \
        Phase_One_Search.cpp Phase_One_Search.hpp
	$(call DisplayCommand,$(COMPILE) Mads.cpp -o $@)

$(OBJ_DIR)/OrthogonalMesh.o: OrthogonalMesh.cpp OrthogonalMesh.hpp
	$(call DisplayCommand,$(COMPILE) OrthogonalMesh.cpp -o $@)

$(OBJ_DIR)/GMesh.o: GMesh.cpp GMesh.hpp OrthogonalMesh.cpp OrthogonalMesh.hpp
	$(call DisplayCommand,$(COMPILE) GMesh.cpp -o $@)

$(OBJ_DIR)/SMesh.o: SMesh.cpp SMesh.hpp OrthogonalMesh.cpp OrthogonalMesh.hpp
	$(call DisplayCommand,$(COMPILE) SMesh.cpp -o $@)

$(OBJ_DIR)/XMesh.o: XMesh.cpp XMesh.hpp OrthogonalMesh.cpp OrthogonalMesh.hpp
	$(call DisplayCommand,$(COMPILE) XMesh.cpp -o $@)

$(OBJ_DIR)/Multi_Obj_Evaluator.o: Multi_Obj_Evaluator.cpp Multi_Obj_Evaluator.hpp Phase_One_Evaluator.hpp
	$(call DisplayCommand,$(COMPILE) Multi_Obj_Evaluator.cpp -o $@)

$(OBJ_DIR)/Model_Sorted_Point.o: Model_Sorted_Point.cpp Model_Sorted_Point.hpp Point.hpp
	$(call DisplayCommand,$(COMPILE) Model_Sorted_Point.cpp -o $@)

$(OBJ_DIR)/Model_Stats.o: Model_Stats.cpp Model_Stats.hpp Double.hpp
	$(call DisplayCommand,$(COMPILE) Model_Stats.cpp -o $@)

$(OBJ_DIR)/NelderMead_Search.o: NelderMead_Search.cpp NelderMead_Search.hpp NelderMead_Simplex_Eval_Point.hpp Mads.hpp
	$(call DisplayCommand,$(COMPILE) NelderMead_Search.cpp -o $@)

$(OBJ_DIR)/NelderMead_Simplex_Eval_Point.o: NelderMead_Simplex_Eval_Point.cpp NelderMead_Simplex_Eval_Point.hpp Set_Element.hpp Eval_Point.hpp
	$(call DisplayCommand,$(COMPILE) NelderMead_Simplex_Eval_Point.cpp -o $@)

$(OBJ_DIR)/nomad.o: nomad.cpp nomad.hpp  Mads.hpp
	$(call DisplayCommand,$(COMPILE) nomad.cpp -o $@)

$(OBJ_DIR)/Parameters.o: Parameters.cpp Parameters.hpp Algo_Parameters.hpp Parameter_Entries.hpp Signature.hpp
	$(call DisplayCommand,$(COMPILE) Parameters.cpp -o $@)

$(OBJ_DIR)/Parameter_Entries.o: Parameter_Entries.cpp Parameter_Entries.hpp Parameter_Entry.hpp
	$(call DisplayCommand,$(COMPILE) Parameter_Entries.cpp -o $@)

$(OBJ_DIR)/Parameter_Entry.o: Parameter_Entry.hpp Parameter_Entry.cpp  Display.hpp Uncopyable.hpp
	$(call DisplayCommand,$(COMPILE) Parameter_Entry.cpp -o $@)

$(OBJ_DIR)/Pareto_Front.o: Pareto_Front.cpp Pareto_Front.hpp Pareto_Point.hpp
	$(call DisplayCommand,$(COMPILE) Pareto_Front.cpp -o $@)

$(OBJ_DIR)/Pareto_Point.o: Pareto_Point.cpp Pareto_Point.hpp Multi_Obj_Evaluator.hpp
	$(call DisplayCommand,$(COMPILE) Pareto_Point.cpp -o $@)

$(OBJ_DIR)/Phase_One_Evaluator.o: Phase_One_Evaluator.cpp Phase_One_Evaluator.hpp Evaluator.hpp
	$(call DisplayCommand,$(COMPILE) Phase_One_Evaluator.cpp -o $@)

$(OBJ_DIR)/Phase_One_Search.o: Phase_One_Search.cpp Phase_One_Search.hpp Mads.hpp \
                    Search.hpp Evaluator_Control.hpp
	$(call DisplayCommand,$(COMPILE) Phase_One_Search.cpp -o $@)

$(OBJ_DIR)/Point.o: Point.cpp Point.hpp Double.hpp
	$(call DisplayCommand,$(COMPILE) Point.cpp -o $@)

$(OBJ_DIR)/Priority_Eval_Point.o: Priority_Eval_Point.cpp Priority_Eval_Point.hpp Eval_Point.hpp \
                       Set_Element.hpp
	$(call DisplayCommand,$(COMPILE) Priority_Eval_Point.cpp -o $@)

$(OBJ_DIR)/Quad_Model.o: Quad_Model.cpp Quad_Model.hpp Cache.hpp Model_Sorted_Point.hpp
	$(call DisplayCommand,$(COMPILE) Quad_Model.cpp -o $@)

$(OBJ_DIR)/Quad_Model_Evaluator.o: Quad_Model_Evaluator.cpp Quad_Model_Evaluator.hpp \
                        Evaluator.hpp Search.hpp
	$(call DisplayCommand,$(COMPILE) Quad_Model_Evaluator.cpp -o $@)

$(OBJ_DIR)/Quad_Model_Search.o: Quad_Model_Search.cpp Quad_Model_Search.hpp Mads.hpp \
                     Quad_Model_Evaluator.hpp
	$(call DisplayCommand,$(COMPILE) Quad_Model_Search.cpp -o $@)

$(OBJ_DIR)/Random_Pickup.o: Random_Pickup.cpp Random_Pickup.hpp RNG.cpp RNG.hpp Uncopyable.hpp
	$(call DisplayCommand,$(COMPILE) Random_Pickup.cpp -o $@)

$(OBJ_DIR)/RNG.o: RNG.cpp RNG.hpp defines.hpp
	$(call DisplayCommand,$(COMPILE) RNG.cpp -o $@)

$(OBJ_DIR)/Signature.o: Signature.cpp Signature.hpp Variable_Group.hpp
	$(call DisplayCommand,$(COMPILE) Signature.cpp -o $@)

$(OBJ_DIR)/Slave.o: Slave.cpp Slave.hpp Evaluator.hpp
	$(call DisplayCommand,$(COMPILE) Slave.cpp -o $@)

$(OBJ_DIR)/Speculative_Search.o: Speculative_Search.cpp Speculative_Search.hpp Mads.hpp Search.hpp \
                      Evaluator_Control.hpp
	$(call DisplayCommand,$(COMPILE) Speculative_Search.cpp -o $@)

$(OBJ_DIR)/Stats.o: Stats.cpp Stats.hpp  Clock.hpp Double.hpp Model_Stats.hpp
	$(call DisplayCommand,$(COMPILE) Stats.cpp -o $@)

$(OBJ_DIR)/utils.o: utils.cpp utils.hpp defines.hpp 
	$(call DisplayCommand,$(COMPILE) utils.cpp -o $@)

$(OBJ_DIR)/Variable_Group.o: Variable_Group.cpp Variable_Group.hpp  Directions.hpp
	$(call DisplayCommand,$(COMPILE) Variable_Group.cpp -o $@)

$(OBJ_DIR)/VNS_Search.o: VNS_Search.cpp VNS_Search.hpp Search.hpp Evaluator_Control.hpp
	$(call DisplayCommand,$(COMPILE) VNS_Search.cpp -o $@)

$(OBJ_DIR)/Sgtelib_Model_Evaluator.o: Sgtelib_Model_Evaluator.cpp Sgtelib_Model_Evaluator.hpp Sgtelib_Model_Manager.hpp Search.hpp Evaluator_Control.hpp 
	$(call DisplayCommand,$(COMPILE) Sgtelib_Model_Evaluator.cpp -o $@)

$(OBJ_DIR)/Sgtelib_Model_Manager.o: Sgtelib_Model_Manager.cpp Sgtelib_Model_Evaluator.hpp Sgtelib_Model_Manager.hpp Parameters.hpp Search.hpp Evaluator_Control.hpp 
	$(call DisplayCommand,$(COMPILE) Sgtelib_Model_Manager.cpp  -o $@)

$(OBJ_DIR)/Sgtelib_Model_Search.o: Sgtelib_Model_Search.cpp Sgtelib_Model_Evaluator.hpp Sgtelib_Model_Manager.hpp Search.hpp LH_Search.hpp Evaluator_Control.hpp 
	$(call DisplayCommand,$(COMPILE) Sgtelib_Model_Search.cpp -o $@)

$(OBJ_DIR)/TrendMatrix_Line_Search.o: TrendMatrix_Line_Search.cpp TrendMatrix_Line_Search.hpp Mads.hpp Search.hpp \
                      Evaluator_Control.hpp 
	$(call DisplayCommand,$(COMPILE) TrendMatrix_Line_Search.cpp -o $@)
