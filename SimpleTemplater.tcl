#!/usr/bin/tclsh

# A Simple Template Parser
package provide "SimpleTemplater" 0.1

namespace eval ::SimpleTemplater {

    set debug 0
    set invalidTemplateString ""
    array set customFilter {}
    set functions {
        for
        if
    }

    set functionsWithIndex {
        if
    }

    array set functionOperators {
        for { in }
        if  { in < > <= >= ni == != }
    }

    array set _op {}
    foreach { key val } [array get functionOperators] {
        foreach v $val {
            set _op($v) ""
        }
    }
    set operators [array names _op]
    unset _op key val v

    set additionalAttributes        "loop.count"
    set objectExpression_1          "(\\w+(?:\\.\\d+|\\.\\w+|\\|\\S+)*|[join $additionalAttributes "|"]|\".*\")"
    set functionPattern             "{% *([join $functions "|"]) +(\\w+(?: *, *\\w+)*) +([join $operators "|"]) +$objectExpression_1 *%}"
    set functionPatternWithIndex    "{% *([join $functionsWithIndex "|"]) +$objectExpression_1 +([join $operators "|"]) +$objectExpression_1 *%}"
    set functionPatternTruthCheck   "{% *(if) +(not |!)? *$objectExpression_1 +%}"
    set functionEndPattern          "{% *end([join $functions "|"]) *%}"
    set lappendCmd                  "lappend ::SimpleTemplater::renderedData"

    proc setConfig { args } {
        variable debug
        variable invalidTemplateString

        foreach key [dict keys $args]  {
            switch $key {
                "-debug" {
                    if { [dict get $args $key] == "true" } {
                        set debug 1
                    } elseif { [dict get $args $key] == "false" } {
                        set debug 0
                    }
                }
                "-invalid_template_string" {
                    set invalidTemplateString [dict get $args $key]
                }
                default {}
            }
        }
    }

    proc dquoteEscape { str } {
        return [regsub -all {"} $str {\"}]
    }

    proc error2Html { str } {
        # regsub -all {(\{|\}|\")} $str {\\\1} str
        regsub -all "\\r\\n" $str "<br/>" str
        regsub -all "\\n" $str "<br/>" str
        regsub -all " " $str "\\&nbsp;" str
        return $str
    }

    proc htmlEscape { str { tick 0 } } {
        regsub -all "&" $str "\\&amp;" str
        regsub -all "\"" $str "\\&quot;" str
        regsub -all "<" $str "\\&lt;" str
        regsub -all ">" $str "\\&gt;" str

        if { $tick } {
            regsub -all "'" $str "\\&#8217;" str
        } else {
            regsub -all "'" $str "\\&#39;" str
        }
        return $str
    }

    proc urlEscape { url } {
        # to be implemented!
    }

    proc escapeJS { url } {
        # to be implemented!
    }

    proc bufferOut { msg } {
        variable _bufferOut

        lappend _bufferOut $msg
    }

    proc executeCommand { cmd } {
        variable debug
        if { $debug } { puts stderr "\[$cmd\]" }
        return "\[$cmd\]"
    }

    proc debugHint { context_var } {
        return [regsub {.*SimpleTemplater::object\((.*)\)} $context_var {\1}]
    }

    proc objectExists { obj_var index { not_loop 0 } } {
        variable invalidTemplateString
        variable invalidTemplateLoopString
        variable debug
        upvar $obj_var object

        set out ""
        set found 0
        if { [info exists object($index)] } {
            set found 1
            set out $object($index)
        } elseif { $not_loop } {
            set out $invalidTemplateString
        } else {
            set out $invalidTemplateLoopString
        }
        if { !$found && $debug } {
            puts stderr "Please check your template var $index"
            # TODO: throw errors
        }
        return $out
    }

    proc listExists { context index { not_loop 0 } } {
        variable invalidTemplateString
        variable invalidTemplateLoopString
        variable debug

        set out ""
        set found 0
        if { $index > -1 && $index < [llength $context] } {
            set found 1
            set out [lindex $context $index]
        } elseif { $not_loop } {
            set out $invalidTemplateString
        } else {
            set out $invalidTemplateLoopString
        }

        if { !$found && $debug } {
            puts stderr "Index ($index) out of range"
            # TODO: throw errors
        }
        return $out
    }

    proc dictExists { context index { not_loop 0 } } {
        variable invalidTemplateString
        variable invalidTemplateLoopString
        variable debug

        set out ""
        set found 0
        if { ![catch { dict exists $context $index } errMsg] && [dict exists $context $index] } {
            set found 1
            set out [dict get $context $index]
        } elseif { $not_loop } {
            set out $invalidTemplateString
        } else {
            set out $invalidTemplateLoopString
        }

        if { !$found && $debug } {
            puts stderr "Key ($index) not found"
            # TODO: throw errors
        }
        return $out
    }

    proc staticData { data } {
        return "{$data}"
    }

    proc registerFilter { args } {
        variable customFilter

        set name [dict get $args "-filter"]
        set proc [dict get $args "-proc"]
        set customFilter($name) $proc
        set customFilter($name,html_escape) 1
        set customFilter($name,tick) 0

        if { [dict exists $args "-safe"] } {
            if { [dict get $args "-safe"] == "true" } {
                set customFilter($name,html_escape) 0
            } elseif { [dict get $args "-safe"] == "false" } {
                set customFilter($name,html_escape) 1
            }
        }

        if { [dict exists $args "-tick"] } {
            if { [dict get $args "-tick"] == "true" } {
                set customFilter($name,tick) 1
            } elseif { [dict get $args "-tick"] == "false" } {
                set customFilter($name,tick) 0
            }
        }
    }

    proc applyFilters { object filter html_escape_var tick_var } {
        upvar $html_escape_var html_escape
        upvar $tick_var tick

        switch $filter {
            safe {
                set html_escape 0
            }
            tick {
                set tick 1
            }
            urlescape {
                # to be implemented!
                # set object "\[urlEscape $object\]"
            }
            escapejs {
                # to be implemented!
                # set object "\[escapeJS $object\]"
            }
            default {}
        }
        return $object
    }

    proc processObject { object { not_loop 0 } } {
        variable debug
        variable customFilter
        variable additionalAttributes

        set htmlEscape 0
        set tick 0
        if { $not_loop } {
            set htmlEscape 1
        }

        lappend objSplit {*}[split $object "|"]
        set object [lindex $objSplit 0]
        set transformFuncs [lrange $objSplit 1 end]
        if { $debug } { puts stderr "object : '$object' transform functions: '$transformFuncs'" }
        set objSplit ""
        lappend objSplit {*}[split $object "."]
        set mainObj [lindex $objSplit 0]
        set rest [lrange $objSplit 1 end]
        if { $object in $additionalAttributes } {
            set newObj "\[::SimpleTemplater::objectExists ::SimpleTemplater::object $object $not_loop\]"
        } else {
            set newObj "\[::SimpleTemplater::objectExists ::SimpleTemplater::object $mainObj $not_loop\]"
            foreach index $rest {
                if { [regexp "^\\d+$" $index] } {
                    set newObj "\[::SimpleTemplater::listExists $newObj $index $not_loop\]"
                } elseif { [regexp "^\\w+$" $index]} {
                    set newObj "\[::SimpleTemplater::dictExists $newObj $index $not_loop\]"
                }
            }
        }

        foreach _filter $transformFuncs {
            foreach { filter _args } [split $_filter ":"] { break }
            set filter [string trim $filter]
            set args ""
            set _args [string trim [string trim $_args] "\""]
            foreach  arg [split $_args ,] {
                lappend args [string trim $arg]
            }
            if { $debug } { puts stderr "filter : $filter args : $args" }
            if [info exists customFilter($filter)] {
                if { $args != "" } {
                    set newObj "\[$customFilter($filter) $newObj $args\]"
                } else {
                    set newObj "\[$customFilter($filter) $newObj\]"
                }
                if { !$customFilter($filter,html_escape) } {
                    set htmlEscape 0
                }
                if { $customFilter($filter,tick) } {
                    set tick 1
                }
                continue
            }
            if { $debug } { puts stderr "No customFilter '$filter' found, looking inbuilt filters" }
            set newObj [applyFilters $newObj $filter htmlEscape tick]
        }

        if { $htmlEscape } {
            return "\[::SimpleTemplater::htmlEscape $newObj $tick\]"
        }
        if { $debug } { puts stderr "final object : '$newObj'" }
        return $newObj
    }

    proc getContext { str } {
        return [subst [processObject $str]]
    }

    proc processFunc_for { params } {
        variable functionOperators
        variable debug

        set function    [lindex $params 0]
        set iter        [lindex $params 1]
        set operator    [lindex $params 2]
        set limiter     [lindex $params 3]

        regsub -all {([][$\\])} $limiter {\\\1} limiter ;# disable command executions
        if { $operator ni $functionOperators($function) } { error "Unsupported operator '$operator' used!" }
        foreach it [split $iter ,] {
            set it [string trim $it]
            lappend newIter ::SimpleTemplater::object($it)
        }
        if { [regexp "^\"(.*)\"$" $limiter --> newLimiter] } {
            if { $debug } { puts stderr "Static limiter: '$limiter'"}
            set limiter [staticData $newLimiter]
        } else {
            if { $debug } { puts stderr "Dynamic limiter: '$limiter'"}
            set limiter [processObject $limiter]
        }
        return "foreach \{ $newIter \} $limiter \{"
    }

    proc processFunc_if { params } {
        variable functionOperators
        variable debug

        set function    [lindex $params 0]
        set iter        [lindex $params 1]
        set operator    [lindex $params 2]
        set limiter     [lindex $params 3]

        regsub -all {([][$\\])} $iter {\\\1} iter       ;# disable command executions
        regsub -all {([][$\\])} $limiter {\\\1} limiter ;# disable command executions
        if { $operator ni $functionOperators($function) } { error "Unsupported operator '$operator' used!" }
        if { [regexp "^\"(.*)\"$" $limiter --> newLimiter] } {
            if { $debug } { puts stderr "Static limiter: '$limiter'"}
            set limiter [staticData $newLimiter]
        } else {
            if { $debug } { puts stderr "Dynamic limiter: '$limiter'"}
            set limiter [processObject $limiter]
        }
        if { [regexp "^\"(.*)\"$" $iter --> newIter] } {
            if { $debug } { puts stderr "Static iter: '$iter'"}
            set iter [staticData {*}$newIter]
        } else {
            if { $debug } { puts stderr "Dynamic iter: '$iter'"}
            set iter [processObject $iter]
        }
        return "if \{ $iter $operator $limiter \} \{"
    }

    proc processFuncWithIndex_if { params } {
        processFunc_if $params
    }

    proc processFuncTruthiness_if { params } {
        variable functionOperators
        variable debug

        set function    [lindex $params 0]
        set operator    [lindex $params 1]
        set var         [lindex $params 2]

        regsub -all {([][$\\])} $var {\\\1} var       ;# disable command executions

        if { [regexp "^\"(.*)\"$" $var --> newVar] } {
            if { $debug } { puts stderr "Static variable: '$var'"}
            set var [staticData {*}$newVar]
        } else {
            if { $debug } { puts stderr "Dynamic variable: '$var'"}
            set var [processObject $var]
        }

        if { $operator ne "" } { set operator "!" }
        return "if \{ ${operator}(($var ne \"\") && ($var != 0)) \} \{"
    }

    proc processLine { line } {
        variable debug
        variable loop

        regsub -all {([][$\\])} $line {\\\1} line ;# disable command executions

        set pos 0
        set char_list [split $line {}]
        set max_pos [llength $char_list]
        if { !$max_pos } { set max_pos -1 }
        set save ""
        set start 0
        set object ""
        set last_open end
        set str ""

        while { $pos <= $max_pos } {
            set double_char "[lindex $char_list $pos][lindex $char_list [expr $pos + 1]]"
            if { $double_char == "\{\{" } {
                set last_open [llength $save]
                lappend save [lindex $char_list $pos]
                incr pos
                set start 1
                set object ""
                set init 1
            } elseif { $start } {
                if { $init } {
                    incr pos
                    set init 0
                }
                if { $double_char == "\}\}" } {
                    lappend str [join [lrange $save 0 [expr $last_open - 1]] ""] [processObject [string trim [join $object ""]] 1]
                    set save ""
                    set object ""
                    set start 0
                    incr pos 2
                } else {
                    lappend object [lindex $char_list $pos]
                    lappend save [lindex $char_list $pos]
                    incr pos
                }
            } else {
                lappend str [lindex $char_list $pos]
                incr pos
            }
        }

        return [dquoteEscape [join $str ""]]
    }

    proc codeGenerator { code } {
        set fh [open generated_code.tcl w]
        puts $fh "#!/usr/bin/tclsh"
        puts $fh "namespace eval ::SimpleTemplater {}"
        puts $fh "array set ::SimpleTemplater::object {\n    [array get ::SimpleTemplater::object]\n}\n"
        puts $fh "$code"
        close $fh
    }

    proc applyExtendsTemplate { templatePath templateContent } {
        set fullText [join $templateContent \n]
        regexp {{%\s+extends\s+("|')(.+)("|')\s+%}} $fullText -> _ tplname
	regexp {{%\s+extends\s+("|')(.+)("|')\s+%}} $fullText -> _ tplname

	if { $tplName != "" } {
	    
	}
    }
	

    proc parser { template_var } {
        upvar $template_var template

        variable object
        variable debug
        variable functionPattern
        variable functionEndPattern
        variable functionPatternWithIndex
        variable functionPatternTruthCheck
        variable lappendCmd
        variable _bufferOut

        set loop_enabled {
            for
        }

        set call_stack ""

        foreach line $template {
            if { [regexp "(^\\s*)$functionPattern" $line --> indent function iter operator limiter] } {
                if { $debug } { puts stderr "function:$function iter:$iter operator:$operator limiter:$limiter" }
                lappend call_stack $function
                set params [list $function $iter $operator $limiter]
                set indent "${indent}[string repeat " " [string length $lappendCmd]]"

                if { $function in $loop_enabled } {
                    bufferOut "${indent}set ::SimpleTemplater::loop(last_loop) \[incr ::SimpleTemplater::loopCnt\]"
                    bufferOut "${indent}set ::SimpleTemplater::loop(\$::SimpleTemplater::loop(last_loop)) 0"
                    bufferOut "${indent}set ::SimpleTemplater::object(loop.count) \$::SimpleTemplater::loop(\$::SimpleTemplater::loop(last_loop))"
                }
                bufferOut "${indent}[processFunc_${function} $params]"
                if { $function in $loop_enabled } {
                    bufferOut "[string repeat " " 4]${indent}incr ::SimpleTemplater::loop(\$::SimpleTemplater::loop(last_loop))"
                    bufferOut "[string repeat " " 4]${indent}set ::SimpleTemplater::object(loop.count) \$::SimpleTemplater::loop(\$::SimpleTemplater::loop(last_loop))"
                }
                continue
            } elseif { [regexp "(^\\s*)$functionPatternWithIndex" $line --> indent function iter operator limiter] } {
                if { $debug } { puts stderr "function:$function iter:$iter operator:$operator limiter:$limiter" }
                lappend call_stack $function
                set params [list $function $iter $operator $limiter]
                set indent "${indent}[string repeat " " [string length $lappendCmd]]"
                bufferOut "${indent}[processFuncWithIndex_${function} $params]"
                continue
            } elseif { [regexp "(^\\s*)$functionPatternTruthCheck" $line --> indent function operator var] } {
                if { $debug } { puts stderr "function:$function operator: $operator variable:$var" }
                lappend call_stack $function
                set params [list $function $operator $var]
                set indent "${indent}[string repeat " " [string length $lappendCmd]]"
                bufferOut "${indent}[processFuncTruthiness_${function} $params]"
                continue
            }

            if {
                [apply { { line out_var } {
                    upvar $out_var out
                    set out ""
                    if { [regexp "(^\\s*){% *(else) *%}" $line --> indent object] } {
                        set out "${indent}\} else \{"
                        return 1
                    }
                    return 0
                }} $line else_block]
            } {
                set indent "[string repeat " " [string length $lappendCmd]]"
                bufferOut "${indent}$else_block"
                continue
            }

            if { [regexp "(^\\s*)$functionEndPattern" $line --> indent function_close] } {
                set function [lindex $call_stack end]
                set call_stack [lrange $call_stack 0 end-1]
                set indent "${indent}[string repeat " " [string length $lappendCmd]]"
                bufferOut " ${indent}\}"
                if { $function in $loop_enabled } {
                    bufferOut "${indent}set ::SimpleTemplater::loop(last_loop) \[incr ::SimpleTemplater::loopCnt -1\]"
                    bufferOut "${indent}set ::SimpleTemplater::object(loop.count) \$::SimpleTemplater::loop(\$::SimpleTemplater::loop(last_loop))"
                }
                continue
            }

            bufferOut "$lappendCmd \"[processLine $line]\""
        }

        return [join $_bufferOut \n]
    }

    proc flushRenderedData {} {
        variable renderedData

        set output $renderedData
        unset renderedData
        return [join $output "\n"]
    }

    proc readTemplate { template_file } {
        set template ""
        set error 0
        set fh [open $template_file r]

        if { [catch {
            while { ![eof $fh] } {
                lappend template [gets $fh]
            }
        } errMsg] } {
            set errorinfo $::errorInfo
            set error 1
        }

        close $fh

        if { $error } { return -code "error" -errorinfo "file read error:\n$errorinfo" $errMsg }
        return $template
    }

    proc loadData { obj_var } {
        variable object
        upvar $obj_var obj

        array set object $obj
    }

    proc init {} {
        variable object
        variable loop
        variable renderedData ""
        variable loopCnt 0
        variable _bufferOut ""
        variable invalidTemplateLoopString ""

        array unset loop
        array set loop [list \
            last_loop 0 \
            0 0 \
        ]
        array unset object
        array set object [list]
    }

    # use to render template with extends and include
    # @param templateDirs list of dirs when is templates files
    # @param templatePath template relative path/name
    # @param ctx template args to interpolation
    proc templateExtends { dir template } {

	upvar $template contents 

	set contents_str [join $contents \n]
	
	if { ![regexp -line {{%\s+extends\s+(.+)\s+%}} $contents_str -> tplName ] } {
	    puts "template does not extends layout"
	    #return [split $templateContent \n]
	    return ;#[lsearch -all -inline -not -exact [split $templateContent \n] {}]
	}

	regsub -line {{%\s+extends\s+(.+)\s+%}} $contents_str {} rc

	set contents_str $rc
	
	# apply extends template, replace blocks
	set extendsFile $dir/$tplName

	if { ![file isfile $extendsFile] } {
	    return -code error "extends $tplName not found at $dir"
	}

	set blockRegex {{%\s*?block\s+(\w+)\s*?%}(.*?){%\s*?endblock\s*?%}}

	set extendsContents [join [readTemplate $extendsFile] \n]

	set matches [regexp -line -all -inline $blockRegex $extendsContents]
	set mainBlocks {}
	    
	foreach {_ blockName blockContent} $matches {
	    lappend mainBlocks $blockName
	}

	set matches [regexp -all -inline $blockRegex $contents_str ]

	set blocks [dict create]
	foreach {_ blockName blockContent} $matches {
	    dict set blocks $blockName $blockContent
	}

	foreach block $mainBlocks {
	    if { ![dict exists $blocks $block] } {
		return -code error \
		    "block $block from template $tplName not found in template $templateFullPath to apply"
	    }
	    
	    set content [dict get $blocks $block]
	    regsub $blockRegex $extendsContents $content rc
	    set extendsContents $rc
	}

	set includeRegex {{%\s*?include\s+(.*?)\s*?%}}
	set matches [regexp -all -inline $includeRegex $extendsContents]

	foreach {_ tplName} $matches {
	    set f $dir/$tplName

	    if { ![file isfile $f] } {
		return -code error "include file $tplName not found at $dir"
	    }
	    
	    set includeContents [join [readTemplate $f] \n]
	    regsub $includeRegex $extendsContents $includeContents rc
	    set extendsContents $rc
	}

	# remove empty lines
	set contents [clearEmptyLines [split $extendsContents \n]]
    }

    proc clearEmptyLines {buff} {
	lsearch -all -inline -not -exact $buff {}    
    }

    proc render { template obj } {
        variable object
        variable debug
        variable loop
        variable loopCnt
        variable _bufferOut
        variable invalidTemplateLoopString

	if {![file exists $template]} {
	    return -code error "template $template not found"
	}

	set contents [readTemplate $template]
	set dir [file dirname $template]
	set contents [templateExtends $dir contents]

        init
        loadData obj
        # parray object
        set output [parser contents]

        if { $debug } {
            puts stderr $output
            codeGenerator $output
        }
        eval $output
        unset object output
        return [flushRenderedData]
    }

    proc renderString { str obj } {
        variable object
        variable debug
        variable loop
        variable loopCnt
        variable _bufferOut
        variable invalidTemplateLoopString

        init
        loadData obj
        # parray object
        set template ""
        regsub "\\r\\n" $str "\\n" str
        foreach line [split $str "\n"] {
            lappend template $line
        }
        set output [parser template]

        if { $debug } {
            puts stderr $output
            codeGenerator $output
        }
        eval $output
        unset object output
        return [flushRenderedData]
    }

    proc compile { template } {
        variable compileCnt

        set ns "st[incr compileCnt]_[clock milliseconds]"
        set template [readTemplate $template]

        init

        namespace eval ::${ns} {
            namespace export execute destroy
            namespace ensemble create
        }

        set ::${ns}::code [parser template]

        proc ::${ns}::execute { data } {
            ::SimpleTemplater::init
            ::SimpleTemplater::loadData data
            eval [set [namespace current]::code]
            unset ::SimpleTemplater::object
            return [::SimpleTemplater::flushRenderedData]
        }

        proc ::${ns}::destroy {} {
            namespace delete [namespace current]
        }

        return $ns
    }

}
