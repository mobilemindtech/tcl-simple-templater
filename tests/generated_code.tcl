#!/usr/bin/tclsh
namespace eval ::SimpleTemplater {}
array set ::SimpleTemplater::object {
    address_book {
                            {
                                name {John Doe}
                                place {USA}
                                phone {001}
                            }
                            {
                                name {David Beck}
                                place {England}
                                phone {002}
                            }
                        } legacy_order_no 1000 sample {[list  [list test00 test01]  [list test10 test11]  [list test12 test13]  [list test14 test15]  ]} item_nos {[list 10 20 30]} item_no dance rows {
                            { hello world }
                            { good bye }
                            { sample value }
                            { blue sky }
                        } compare {[list 10 10]}
}

lappend ::SimpleTemplater::renderedData ""
lappend ::SimpleTemplater::renderedData "<html>"
lappend ::SimpleTemplater::renderedData "    <header>"
lappend ::SimpleTemplater::renderedData "        <script type=\"text/javascript\">"
lappend ::SimpleTemplater::renderedData "            alert('Welcome');"
lappend ::SimpleTemplater::renderedData "        </script>"
lappend ::SimpleTemplater::renderedData "    </header>"
lappend ::SimpleTemplater::renderedData "    <body>"
lappend ::SimpleTemplater::renderedData "        <table border=\"1\">"
                                                   set ::SimpleTemplater::loop(last_loop) [incr ::SimpleTemplater::loopCnt]
                                                   set ::SimpleTemplater::loop($::SimpleTemplater::loop(last_loop)) 0
                                                   set ::SimpleTemplater::object(loop.count) $::SimpleTemplater::loop($::SimpleTemplater::loop(last_loop))
                                                   foreach { ::SimpleTemplater::object(addr) } [::SimpleTemplater::objectExists ::SimpleTemplater::object address_book 0] {
                                                       incr ::SimpleTemplater::loop($::SimpleTemplater::loop(last_loop))
                                                       set ::SimpleTemplater::object(loop.count) $::SimpleTemplater::loop($::SimpleTemplater::loop(last_loop))
lappend ::SimpleTemplater::renderedData "                <tr><td colspan=\"2\"><h4>[::SimpleTemplater::htmlEscape [::SimpleTemplater::objectExists ::SimpleTemplater::object loop.count 1] 0]. [::SimpleTemplater::htmlEscape [::SimpleTemplater::dictExists [::SimpleTemplater::objectExists ::SimpleTemplater::object addr 1] name 1] 0]</h4></td></tr>"
lappend ::SimpleTemplater::renderedData "                <tr><td>Firstname</td><td>[::SimpleTemplater::htmlEscape [::SimpleTemplater::listExists [::SimpleTemplater::dictExists [::SimpleTemplater::objectExists ::SimpleTemplater::object addr 1] name 1] 0 1] 0]</td></tr>"
lappend ::SimpleTemplater::renderedData "                <tr><td>Lastname</td><td>[::SimpleTemplater::htmlEscape [::SimpleTemplater::listExists [::SimpleTemplater::dictExists [::SimpleTemplater::objectExists ::SimpleTemplater::object addr 1] name 1] 1 1] 0]</td></tr>"
lappend ::SimpleTemplater::renderedData "                <tr><td>Place</td><td>[::SimpleTemplater::htmlEscape [::SimpleTemplater::dictExists [::SimpleTemplater::objectExists ::SimpleTemplater::object addr 1] place 1] 0]</td></tr>"
lappend ::SimpleTemplater::renderedData "                <tr><td>Phone</td><td>[::SimpleTemplater::htmlEscape [::SimpleTemplater::dictExists [::SimpleTemplater::objectExists ::SimpleTemplater::object addr 1] phone 1] 0]</td></tr>"
lappend ::SimpleTemplater::renderedData "                <tr/>"
                                                    }
                                                   set ::SimpleTemplater::loop(last_loop) [incr ::SimpleTemplater::loopCnt -1]
                                                   set ::SimpleTemplater::object(loop.count) $::SimpleTemplater::loop($::SimpleTemplater::loop(last_loop))
lappend ::SimpleTemplater::renderedData "        </table>"
lappend ::SimpleTemplater::renderedData "    </body>"
lappend ::SimpleTemplater::renderedData "</html>"
lappend ::SimpleTemplater::renderedData ""
lappend ::SimpleTemplater::renderedData ""
