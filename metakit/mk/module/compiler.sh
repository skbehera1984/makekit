DEPENDS="core platform"

load()
{
    #
    # Helper functions for make() stage
    #
    mk_compile()
    {
	mk_push_vars SOURCE HEADERDEPS DEPS INCLUDEDIRS CPPFLAGS CFLAGS PIC
	mk_parse_params

	case "$SOURCE" in
	    *.c)
		_object="${SOURCE%.c}-${MK_SYSTEM%/*}-${MK_SYSTEM#*/}.o"
		;;
	    *)
		mk_fail "Unsupported file type: $SOURCE"
		;;
	esac

	for _header in ${HEADERDEPS}
	do
	    if _mk_contains "$_header" ${MK_INTERNAL_HEADERS}
	    then
		DEPS="$DEPS '${MK_INCLUDEDIR}/${_header}'"
	    fi
	done
	
	mk_resolve_target "${SOURCE}"
	_res="$result"

	mk_target \
	    TARGET="$_object" \
	    DEPS="$DEPS '$SOURCE'" \
	    mk_run_script compile %INCLUDEDIRS %CPPFLAGS %CFLAGS %PIC '$@' "$_res"

	mk_pop_vars
    }
    
    _mk_library()
    {
	unset _deps _objects
	
	_mk_emit "#"
	_mk_emit "# library ${LIB} ($MK_SYSTEM) from ${MK_SUBDIR#/}"
	_mk_emit "#"
	_mk_emit ""

	case "$INSTALL" in
	    no)
		_library="lib${LIB}${MK_LIB_EXT}"
		;;
	    *)
		_library="$MK_LIBDIR/lib${LIB}${MK_LIB_EXT}"
		;;
	esac

	# Perform pathname expansion on SOURCES
	mk_expand_pathnames "${SOURCES}" "${MK_SOURCE_DIR}${MK_SUBDIR}"

	mk_unquote_list "$result"
	for _source in "$@"
	do
	    mk_compile \
		SOURCE="$_source" \
		HEADERDEPS="$HEADERDEPS" \
		INCLUDEDIRS="$INCLUDEDIRS" \
		CPPFLAGS="$CPPFLAGS" \
		CFLAGS="$CFLAGS" \
		PIC="yes" \
		DEPS="$DEPS"
	    
	    mk_quote "$result"
	    _deps="$_deps $result"
	    _objects="$_objects $result"
	done
	
	mk_unquote_list "${GROUPS}"
	for _group in "$@"
	do
	    _deps="$_deps '$_group'"
	done
	
	for _lib in ${LIBDEPS}
	do
	    if _mk_contains "$_lib" ${MK_INTERNAL_LIBS}
	    then
		_deps="$_deps '$MK_LIBDIR/lib${_lib}${MK_LIB_EXT}'"
	    fi
	done

	mk_target \
	    TARGET="$_library" \
	    DEPS="${_deps}" \
	    mk_run_script link MODE=library %GROUPS %LIBDEPS %LIBDIRS %LDFLAGS %VERSION '$@' "*${OBJECTS} ${_objects}"
	
	if [ "$INSTALL" != "no" ]
	then
	    mk_add_all_target "$result"
	fi
    }

    mk_library()
    {
	mk_push_vars INSTALL LIB SOURCES GROUPS CPPFLAGS CFLAGS LDFLAGS LIBDEPS HEADERDEPS LIBDIRS INCLUDEDIRS VERSION DEPS OBJECTS
	mk_parse_params

	_mk_library "$@"

	MK_INTERNAL_LIBS="$MK_INTERNAL_LIBS $LIB"

	mk_pop_vars
    }

    mk_dso()
    {
	mk_push_vars INSTALL DSO SOURCES GROUPS CPPFLAGS CFLAGS LDFLAGS LIBDEPS HEADERDEPS LIBDIRS INCLUDEDIRS VERSION OBJECTS DEPS
	mk_parse_params
	
	unset _deps

	_mk_emit "#"
	_mk_emit "# dso ${DSO} ($MK_SYSTEM) from ${MK_SUBDIR#/}"
	_mk_emit "#"
	_mk_emit ""

	case "$INSTALL" in
	    no)
		_library="${DSO}${MK_DSO_EXT}"
		;;
	    *)
		_library="${MK_LIBDIR}/${DSO}${MK_DSO_EXT}"
		;;
	esac
	
	# Perform pathname expansion on SOURCES
	mk_expand_pathnames "${SOURCES}"

	mk_unquote_list "$result"
	for _source in "$@"
	do
	    mk_compile \
		SOURCE="$_source" \
		HEADERDEPS="$HEADERDEPS" \
		INCLUDEDIRS="$INCLUDEDIRS" \
		CPPFLAGS="$CPPFLAGS" \
		CFLAGS="$CFLAGS" \
		PIC="yes" \
		DEPS="$DEPS"
	    
	    mk_quote "$result"
	    _deps="$_deps $result"
	    OBJECTS="$OBJECTS $result"
	done
	
	mk_unquote_list "${GROUPS}"
	for _group in "$@"
	do
	    _deps="$_deps '$_group'"
	done
	
	for _lib in ${LIBDEPS}
	do
	    if _mk_contains "$_lib" ${MK_INTERNAL_LIBS}
	    then
		_deps="$_deps '${MK_LIBDIR}/lib${_lib}${MK_LIB_EXT}'"
	    fi
	done
	
	mk_target \
	    TARGET="$_library" \
	    DEPS="$_deps" \
	    mk_run_script link MODE=dso %GROUPS %LIBDEPS %LIBDIRS %LDFLAGS '$@' "*${OBJECTS}"

	if [ "$INSTALL" != "no" ]
	then
	    mk_add_all_target "$result"
	fi

	mk_pop_vars
    }

    mk_group()
    {
	mk_push_vars GROUP SOURCES CPPFLAGS CFLAGS LDFLAGS LIBDEPS \
	             HEADERDEPS GROUPDEPS LIBDIRS INCLUDEDIRS OBJECTS DEPS
	mk_parse_params

	unset _deps

	_mk_emit "#"
	_mk_emit "# group ${GROUP} ($MK_SYSTEM) from ${MK_SUBDIR#/}"
	_mk_emit "#"
	_mk_emit ""

	# Perform pathname expansion on SOURCES
	mk_expand_pathnames "${SOURCES}" "${MK_SOURCE_DIR}${MK_SUBDIR}"

	mk_unquote_list "$result"
	for _source in "$@"
	do
	    mk_compile \
		SOURCE="$_source" \
		HEADERDEPS="$HEADERDEPS" \
		INCLUDEDIRS="$INCLUDEDIRS" \
		CPPFLAGS="$CPPFLAGS" \
		CFLAGS="$CFLAGS" \
		PIC="yes" \
		DEPS="$DEPS"
	    
	    mk_quote "$result"
	    _deps="$_deps $result"
	    OBJECTS="$OBJECTS $result"
	done
	
	mk_unquote_list "${GROUPDEPS}"
	for _group in "$@"
	do
	    _deps="$_deps '$_group'"
	done
	
	for _lib in ${LIBDEPS}
	do
	    if _mk_contains "$_lib" ${MK_INTERNAL_LIBS}
	    then
		_deps="$_deps '${MK_LIBDIR}/lib${_lib}${MK_LIB_EXT}'"
	    fi
	done

	mk_target \
	    TARGET="$GROUP" \
	    DEPS="$_deps" \
	    mk_run_script group %GROUPDEPS %LIBDEPS %LIBDIRS %LDFLAGS '$@' "*${OBJECTS}"

	mk_pop_vars
    }
    
    mk_program()
    {
	mk_push_vars \
	    PROGRAM SOURCES OBJECTS GROUPS CPPFLAGS CFLAGS \
	    LDFLAGS LIBDEPS HEADERDEPS DEPS LIBDIRS INCLUDEDIRS INSTALLDIR INSTALL
	mk_parse_params
	
	unset _deps

	if [ -z "$INSTALLDIR" ]
	then
	    # Default to installing programs in bin dir
	    if [ "${MK_SYSTEM%/*}" = "build" ]
	    then
		INSTALLDIR="@${MK_RUN_BINDIR}"
	    else
		INSTALLDIR="$MK_BINDIR"
	    fi
	fi

	case "$INSTALL" in
	    no)
		_executable="${PROGRAM}"
		;;
	    *)
		_executable="${INSTALLDIR}/${PROGRAM}"
		;;
	esac

	if [ "${MK_SYSTEM%/*}" = "build" ]
	then
	    _libdir="@${MK_RUNMK_LIBDIR}"
	else
	    _libdir="$MK_LIBDIR"
	fi
	
	_mk_emit "#"
	_mk_emit "# program ${PROGRAM} ($MK_SYSTEM) from ${MK_SUBDIR#/}"
	_mk_emit "#"
	_mk_emit ""

	# Perform pathname expansion on SOURCES
	mk_expand_pathnames "${SOURCES}" "${MK_SOURCE_DIR}${MK_SUBDIR}"

	mk_unquote_list "$result"
	for _source in "$@"
	do
	    mk_compile \
		SOURCE="$_source" \
		HEADERDEPS="$HEADERDEPS" \
		INCLUDEDIRS="$INCLUDEDIRS" \
		CPPFLAGS="$CPPFLAGS" \
		CFLAGS="$CFLAGS" \
		PIC="yes" \
		DEPS="$DEPS"
	    
	    mk_quote "$result"
	    _deps="$_deps $result"
	    OBJECTS="$OBJECTS $result"
	done
	
	mk_unquote_list "${GROUPS}"
	for _group in "$@"
	do
	    _deps="$_deps '$_group'"
	done

	for _lib in ${LIBDEPS}
	do
	    if _mk_contains "$_lib" ${MK_INTERNAL_LIBS}
	    then
		_deps="$_deps '${_libdir}/lib${_lib}${MK_LIB_EXT}'"
	    fi
	done
	
	mk_target \
	    TARGET="$_executable" \
	    DEPS="$_deps" \
	    mk_run_script link MODE=program %GROUPS %LIBDEPS %LDFLAGS '$@' "*${OBJECTS}"

	if [ "$INSTALL" != "no" ]
	then
	    if [ "${MK_SYSTEM%/*}" = "build" ]
	    then
		MK_INTERNAL_PROGRAMS="$MK_INTERNAL_PROGRAMS $PROGRAM"
	    else
		mk_add_all_target "$result"
	    fi
	fi

	mk_pop_vars
    }
    
    mk_headers()
    {
	mk_push_vars HEADERS MASTER INSTALLDIR HEADERDEPS DEPS
	INSTALLDIR="${MK_INCLUDEDIR}"
	mk_parse_params
	
	unset _all_headers
	
	_mk_emit "#"
	_mk_emit "# headers from ${MK_SUBDIR#/}"
	_mk_emit "#"
	_mk_emit ""
	
	for _header in ${HEADERDEPS}
	do
	    if _mk_contains "$_header" ${MK_INTERNAL_HEADERS}
	    then
		DEPS="$DEPS '${MK_INCLUDEDIR}/${_header}'"
	    fi
	done

	mk_expand_pathnames "${HEADERS}"

	mk_unquote_list "$result"
	for _header in "$@"
	do
	    mk_resolve_target "$_header"
	    
	    mk_target \
	        TARGET="${INSTALLDIR}/${_header}" \
		DEPS="'$_header' $DEPS" \
		mk_run_script install '$@' "${result}"

	    mk_add_all_target "$result"

	    _rel="${INSTALLDIR#$MK_INCLUDEDIR/}"
	    
	    if [ "$_rel" != "$INSTALLDIR" ]
	    then
		_rel="$_rel/$_header"
	    else
		_rel="$_header"
	    fi
	    
	    MK_INTERNAL_HEADERS="$MK_INTERNAL_HEADERS $_rel"

	    _all_headers="$_all_headers $result"
	done
	
	DEPS="$DEPS $_all_headers"

	mk_expand_pathnames "${MASTER}"

	mk_unquote_list "$result"
	for _header in "$@"
	do
	    mk_resolve_target "$_header"
	      
	    mk_target \
	        TARGET="${INSTALLDIR}/${_header}" \
		DEPS="'$_header' $DEPS" \
		mk_run_script install '$@' "${result}"

	    mk_add_all_target "$result"

	    _rel="${INSTALLDIR#$MK_INCLUDEDIR/}"
	    
	    if [ "$_rel" != "$INSTALLDIR" ]
	    then
		_rel="$_rel/$_header"
	    else
		_rel="$_header"
	    fi
	    
	    MK_INTERNAL_HEADERS="$MK_INTERNAL_HEADERS $_rel"
	done

	mk_pop_vars
    }

    #
    # Helper functions for configure() stage
    # 

    mk_define()
    {
	mk_push_vars cond
	mk_parse_params

	if [ -n "$MK_CONFIG_HEADER" ]
	then
	    _name="$1"

	    _mk_define_name "$MK_SYSTEM"
	    cond="_MK_$result"
   
	    if [ "$#" -eq '2' ]
	    then
		result="$2"
	    else
		mk_get "$_name"
	    fi
	    
	    mk_write_config_header "#if defined($cond)"
	    mk_write_config_header "#define $_name $result"
	    mk_write_config_header "#endif"
	fi

	mk_pop_vars
    }

    mk_define_always()
    {
	if [ -n "$MK_CONFIG_HEADER" ]
	then
	    _name="$1"

	    if [ "$#" -eq '2' ]
	    then
		result="$2"
	    else
		mk_get "$_name"
	    fi
	    mk_write_config_header "#define $_name $result"
	fi
    }
    
    mk_write_config_header()
    {
	echo "$*" >&5
    }
    
    _mk_close_config_header()
    {
	if [ -n "${MK_CONFIG_HEADER}" ]
	then
	    cat >&5 <<EOF

#endif
EOF
	    exec 5>&-
	    
	    if [ -f "${MK_CONFIG_HEADER}" ] && diff "${MK_CONFIG_HEADER}" "${MK_CONFIG_HEADER}.new" >/dev/null 2>&1
	    then
	    # The config header has not changed, so don't touch the timestamp on the file */
		rm -f "${MK_CONFIG_HEADER}.new"
	    else
		mv "${MK_CONFIG_HEADER}.new" "${MK_CONFIG_HEADER}"
	    fi
	    
	    MK_CONFIG_HEADER=""
	fi
    }
    
    mk_config_header()
    {
	mk_push_vars HEADER
	mk_parse_params
	
	_mk_close_config_header
	
	[ -z "$HEADER" ] && HEADER="$1"
	
	MK_CONFIG_HEADER="${MK_OBJECT_DIR}${MK_SUBDIR}/${HEADER}"
	MK_CONFIG_HEADERS="$MK_CONFIG_HEADERS '$MK_CONFIG_HEADER'"
	
	mkdir -p "${MK_CONFIG_HEADER}%/*"
	
	mk_msg "config header ${MK_CONFIG_HEADER#${MK_OBJECT_DIR}/}"
	
	exec 5>"${MK_CONFIG_HEADER}.new"
	
	cat >&5 <<EOF
/* Generated by MetaKit */

#ifndef __MK_CONFIG_H__
#define __MK_CONFIG_H__

EOF
	
	mk_add_configure_output "$MK_CONFIG_HEADER"
	
	mk_pop_vars
    }

    _mk_build_test()
    {
	__test="${2%.*}"
	
	case "${1}" in
	    compile)
		(
		    eval "exec ${MK_LOG_FD}>&-"
		    MK_LOG_FD=""
		    mk_run_script compile \
			DISABLE_DEPGEN=yes \
			CPPFLAGS="$CPPFLAGS" \
			CFLAGS="$CFLAGS" \
			"${__test}.o" "${__test}.c"
		) >&${MK_LOG_FD} 2>&1	    
		_ret="$?"
		rm -f "${__test}.o"
		;;
	    link-program|run-program)
		(
                    eval "exec ${MK_LOG_FD}>&-"
		    MK_LOG_FD=""
		    mk_run_script link \
			MODE=program \
			LIBDEPS="$LIBDEPS" \
			LDFLAGS="$CPPFLAGS $CFLAGS $LDFLAGS" \
			"${__test}" "${__test}.c"
		) >&${MK_LOG_FD} 2>&1
		_ret="$?"
		if [ "$_ret" -eq 0 -a "$1" = "run-program" ]
		then
		    ./"${__test}"
		    _ret="$?"
		fi
		rm -f "${__test}"
		;;
	    *)
		mk_fail "Unsupported build type: ${1}"
		;;
	esac

	if [ "$_ret" -ne 0 ]
	then
	    {
		echo ""
		echo "Failed code:"
		echo ""
		cat "${__test}.c" | awk 'BEGIN { no = 1; } { printf("%3i  %s\n", no, $0); no++; }'
		echo ""
	    } >&${MK_LOG_FD}
	fi

	rm -f "${__test}.c"

	return "$_ret"
    }
    
    mk_try_compile()
    {
	mk_push_vars CODE HEADERDEPS
	mk_parse_params
	
	{
	    for _include in ${HEADERDEPS}
	    do
		echo "#include <${_include}>"
	    done
	    
	    cat <<EOF
int main(int argc, char** argv)
{
${CODE}
}
EOF
	} > .check.c

	_mk_build_test compile ".check.c"
    	_ret="$?"

	mk_pop_vars

	return "$_ret"
    }
    
    mk_check_header()
    {
	mk_push_vars HEADER FAIL CPPFLAGS CFLAGS
	mk_parse_params

	CFLAGS="$CFLAGS -Wall -Werror"

	_mk_define_name "HAVE_$HEADER"
	_defname="$result"
	_varname="$_defname"

	if mk_check_cache "$_varname"
	then
	    _result="$result"
	elif _mk_contains "$HEADER" ${MK_INTERNAL_HEADERS}
	then
	    _result="internal"
	    mk_cache "$_varname" "$_result"
	else
	    {
		echo "#include <${HEADER}>"
		echo ""
		
		cat <<EOF
int main(int argc, char** argv)
{
    return 0;
}
EOF
	    } > .check.c
	    mk_log "running compile test for header: $HEADER"
	    if _mk_build_test compile ".check.c"
	    then
		_result="external"
	    else
		_result="no"
	    fi
	    
	    mk_cache "$_varname" "$_result"
	fi

	mk_msg "header $HEADER: $_result ($MK_SYSTEM)"
	
	case "$_result" in
	    external|internal)
		mk_define "$_defname" "1"
		mk_pop_vars
		return 0
		;;
	    no)
		if [ "$FAIL" = "yes" ]
		then
		    mk_fail "missing header: $HEADER"
		fi
		mk_pop_vars
		return 1
		;;
	esac
    }
    
    mk_check_function()
    {
	mk_push_vars LIBDEPS FUNCTION HEADERDEPS CPPFLAGS LDFLAGS CFLAGS FAIL PROTOTYPE
	mk_parse_params

	CFLAGS="$CFLAGS -Wall -Werror"

	if [ -n "$PROTOTYPE" ]
	then
	    _parts="`echo "$PROTOTYPE" | sed 's/^\(.*[^a-zA-Z_]\)\([a-zA-Z_][a-zA-Z0-9_]*\) *(\([^)]*\)).*$/\1|\2|\3/g'`"
	    _ret="${_parts%%|*}"
	    _parts="${_parts#*|}"
	    FUNCTION="${_parts%%|*}"
	    _args="${_parts#*|}"
	    _checkname="$PROTOTYPE"
	    _mk_define_name "HAVE_$PROTOTYPE"
	    _defname="$result"
	else
	    _checkname="$FUNCTION()"
	    _mk_define_name "HAVE_$FUNCTION"
	    _defname="$result"
	fi
	
	_varname="$_defname"
	
	if mk_check_cache "$_varname"
	then
	    _result="$result"
	else
	    {
		for _include in ${HEADERDEPS}
		do
		    echo "#include <${_include}>"
		done
		
		echo ""
		
		if [ -n "$PROTOTYPE" ]
		then
		    cat <<EOF
int main(int argc, char** argv)
{
    $_ret (*__func)($_args) = &$FUNCTION;
    return __func ? 0 : 1;
}
EOF
		else
		    cat <<EOF
int main(int argc, char** argv)
{
    void* __func = &$FUNCTION;
    return __func ? 0 : 1;
}
EOF
		fi
	    } >.check.c
	    mk_log "running link test for function: $_checkname"
	    if _mk_build_test 'link-program' ".check.c"
	    then
		_result="yes"
	    else
		_result="no"
	    fi

	    mk_cache "$_varname" "$_result"
	fi

	mk_msg "function $_checkname: $_result ($MK_SYSTEM)"
	
	case "$_result" in
	    yes)
		mk_define "$_defname" "1"
		mk_pop_vars
		return 0
		;;
	    no)
		if [ "$FAIL" = "yes" ]
		then
		    mk_fail "missing function: $FUNCTION"
		fi
		mk_pop_vars
		return 1
		;;
	esac
    }

    mk_check_library()
    {
	mk_push_vars LIBDEPS LIB CPPFLAGS LDFLAGS CFLAGS FAIL
	mk_parse_params

	CFLAGS="$CFLAGS -Wall -Werror"
	LIBDEPS="$LIBDEPS $LIB"
	
	_mk_define_name "HAVE_LIB_$LIB"
	_defname="$result"
	_varname="$_defname"
	
	if mk_check_cache "$_varname"
	then
	    _result="$result"
	elif _mk_contains "$LIB" ${MK_INTERNAL_LIBS}
	then
	    _result="internal"
	    mk_cache "$_varname" "$_result"
	else
	    {
		cat <<EOF
int main(int argc, char** argv)
{
    return 0;
}
EOF
	    } >.check.c
	    mk_log "running link test for library: $LIBRARY"
	    if _mk_build_test 'link-program' ".check.c"
	    then
		_result="external"
	    else
		_result="no"
	    fi
	    
	    mk_cache "$_varname" "$_result"
	fi
	
	mk_msg "library $LIB: $_result ($MK_SYSTEM)"

	_varname="${_varname#HAVE_}"
	mk_declare_system_var "$_varname"
	
	case "$_result" in
	    external|internal)
		mk_set "$_varname" "$LIB"
		mk_define "$_defname" 1
		mk_pop_vars
		return 0
		;;
	    no)
		if [ "$FAIL" = "yes" ]
		then
		    mk_fail "missing library: $LIB"
		fi
		mk_set "$_varname" ""
		mk_pop_vars
		return 1
		;;
	esac
    }

    _mk_check_sizeof()
    {
	_mk_define_name "SIZEOF_$TYPE"
	_defname="$result"
	_varname="$_defname"

	if mk_check_cache "$_varname"
	then
	    _result="$result"
	else
	    {
		for _include in ${HEADERDEPS}
		do
		    echo "#include <${_include}>"
		done
		
		echo ""
		
		cat <<EOF
int main(int argc, char** argv)
{ 
    printf("%lu\n", (unsigned long) sizeof($TYPE));
    return 0;
}
EOF
	    } > .check.c
	    mk_log "running run test for sizeof($TYPE)"
	    if _mk_build_test 'run-program' .check.c >".result"
	    then
		read _result <.result
		rm -f .result
	    else
		rm -f .result
		mk_fail "could not determine sizeof($TYPE)"
	    fi
	    
	    mk_cache "$_varname" "$_result"

	    mk_define "$_defname" "$_result"
	fi

	mk_msg "sizeof($TYPE): $_result ($MK_SYSTEM)"
    }

    mk_check_sizeof()
    {
	mk_push_vars TYPE HEADERDEPS CPPFLAGS LDFLAGS CFLAGS LIBDEPS
	mk_parse_params

	if [ -z "$TYPE" ]
	then
	    TYPE="$1"
	fi

	CFLAGS="$CFLAGS -Wall -Werror"
	HEADERDEPS="$HEADERDEPS stdio.h"

	_mk_check_sizeof

	mk_pop_vars
    }

    mk_check_endian()
    {
	mk_push_vars CPPFLAGS LDFLAGS CFLAGS LIBDEPS
	mk_parse_params

	CFLAGS="$CFLAGS -Wall -Werror"
	HEADERDEPS="$HEADERDEPS stdio.h"
	
	_varname="ENDIANNESS"
	
	if mk_check_cache "$_varname"
	then
	    _result="$result"
	else
	    {
		    cat <<EOF
#include <stdio.h>

int main(int argc, char** argv)
{ 
    union
    {
      int a;
      char b[sizeof(int)];
    } u;

    u.a = 1;

    if (u.b[0] == 1)
    {
        printf("little\n");
    }
    else
    {
        printf("big\n");
    }

    return 0;
}
EOF
	    } > .check.c
	    mk_log "running run test for endianness"
	    if _mk_build_test 'run-program' .check.c >.result
	    then
		read _result <.result
		rm -f .result
	    else
		rm -f .result
		mk_fail "could not determine endianness"
	    fi
	    
	    mk_cache "$_varname" "$_result"

	    if [ "$_result" = "big" ]
	    then
		mk_define WORDS_BIGENDIAN 1
	    fi
	fi

	mk_msg "endianness: $_result ($MK_SYSTEM)"
	
	mk_pop_vars
    }
    
    mk_check_functions()
    {
	mk_push_vars LIBDEPS FUNCTIONS PROTOTYPES HEADERDEPS CPPFLAGS LDFLAGS CFLAGS FAIL
	mk_parse_params
	
	for _name in ${FUNCTIONS} "$@"
	do
	    mk_check_function \
		FAIL="$FAIL" \
		FUNCTION="$_name" \
		HEADERDEPS="$HEADERDEPS" \
		CPPFLAGS="$CPPFLAGS" \
		LDFLAGS="$LDFLAGS" \
		CFLAGS="$CFLAGS" \
		LIBDEPS="$LIBDEPS"
	done

	mk_pop_vars
    }

    mk_check_libraries()
    {
	mk_push_vars LIBS LIBDEPS CPPFLAGS LDFLAGS CFLAGS FAIL
	mk_parse_params
	
	for _name in ${LIBS} "$@"
	do
	    mk_check_library \
		FAIL="$FAIL" \
		LIB="$_name" \
		CPPFLAGS="$CPPFLAGS" \
		LDFLAGS="$LDFLAGS" \
		CFLAGS="$CFLAGS" \
		LIBDEPS="$LIBDEPS"
	done

	mk_pop_vars
    }
    
    mk_check_headers()
    {
	mk_push_vars HEADERS FAIL CPPFLAGS CFLAGS
	mk_parse_params
	
	for _name in ${HEADERS} "$@"
	do
	    mk_check_header \
		HEADER="$_name" \
		FAIL="$FAIL" \
		CPPFLAGS="$CPPFLAGS" \
		CFLAGS="$CFLAGS"
	done

	mk_pop_vars
    }
}

option()
{
    mk_option \
	VAR="CC" \
	PARAM="program" \
	DEFAULT="gcc" \
	HELP="Default C compiler"

    MK_DEFAULT_CC="$CC"

    mk_option \
	VAR="CPPFLAGS" \
	PARAM="flags" \
	DEFAULT="" \
	HELP="Default C preprocessor flags"

    MK_DEFAULT_CPPFLAGS="$CPPFLAGS"

    mk_option \
	VAR="CFLAGS" \
	PARAM="flags" \
	DEFAULT="" \
	HELP="Default C compiler flags"

    MK_DEFAULT_CFLAGS="$CFLAGS"

    mk_option \
	VAR="LDFLAGS" \
	PARAM="flags" \
	DEFAULT="" \
	HELP="Default linker flags"

    MK_DEFAULT_LDFLAGS="$LDFLAGS"

    unset CC CPPFLAGS CFLAGS LDFLAGS

    for _sys in build host
    do
	_mk_define_name "MK_${_sys}_ISAS"
	mk_get "$result"
	
	for _isa in ${result}
	do
	    _mk_define_name "$_sys/${_isa}"
	    _def="$result"

	    _mk_define_name "MK_${_sys}_ARCH"
	    mk_get "$result"
	    
	    case "${MK_DEFAULT_CC}-${result}-${_isa}" in
		*gcc*-x86*-x86_32)
		    _default_cc="$MK_DEFAULT_CC -m32"
		    ;;
		*gcc*-x86*-x86_64)
		    _default_cc="$MK_DEFAULT_CC -m64"
		    ;;
		*)
		    _default_cc="$MK_DEFAULT_CC"
		    ;;
	    esac
	    
	    mk_option \
		VAR="${_def}_CC" \
		DEFAULT="$_default_cc" \
		HELP="C compiler ($_sys/$_isa)"
	    
	    mk_option \
		VAR="${_def}_CPPFLAGS" \
		DEFAULT="$MK_DEFAULT_CPPFLAGS" \
		HELP="C preprocessor flags ($_sys/$_isa)"
	    
	    mk_option \
		VAR="${_def}_CFLAGS" \
		DEFAULT="$MK_DEFAULT_CFLAGS" \
		HELP="C compiler flags ($_sys/$_isa)"
	    
	    mk_option \
		VAR="${_def}_LDFLAGS" \
		DEFAULT="$MK_DEFAULT_LDFLAGS" \
		HELP="Linker flags ($_sys/$_isa)"
	done
    done
}

configure()
{
    mk_declare_system_var MK_CC MK_CPPFLAGS MK_CFLAGS MK_LDFLAGS
    mk_declare_system_var EXPORT=no MK_INTERNAL_LIBS

    mk_msg "default C compiler: $MK_DEFAULT_CC"
    mk_msg "default C preprocessor flags: $MK_DEFAULT_CPPFLAGS"
    mk_msg "default C compiler flags: $MK_DEFAULT_CFLAGS"
    mk_msg "default linker flags: $MK_DEFAULT_LDFLAGS"

    for _sys in build host
    do
	_mk_define_name "MK_${_sys}_ISAS"
	mk_get "$result"
	
	for _isa in ${result}
	do
	    _mk_define_name "$_sys/$_isa"
	    _def="$result"

	    mk_get "${_def}_CC"
	    mk_msg "C compiler ($_sys/$_isa): $result"
	    mk_set_system_var SYSTEM="$_sys/$_isa" MK_CC "$result"

	    mk_get "${_def}_CPPFLAGS"
	    mk_msg "C preprocessor flags ($_sys/$_isa): $result"
	    mk_set_system_var SYSTEM="$_sys/$_isa" MK_CPPFLAGS "$result"

	    mk_get "${_def}_CFLAGS"
	    mk_msg "C compiler flags ($_sys/$_isa): $result"
	    mk_set_system_var SYSTEM="$_sys/$_isa" MK_CFLAGS "$result"

	    mk_get "${_def}_LDFLAGS"
	    mk_msg "linker flags ($_sys/$_isa): $result"
	    mk_set_system_var SYSTEM="$_sys/$_isa" MK_LDFLAGS "$result"
	done
    done

    # Register a hook to finish up the current config header at
    # the end of each configure() function
    mk_add_configure_posthook _mk_close_config_header
}

