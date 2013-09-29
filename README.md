SimpleTemplater
===================

A simple html template parser for TCL (inspired from Python Django)
## Synopsis
Converts a HTML template like this
```html
<!-- File ex2.tpl -->
<html>
    <header>
        <script type="text/javascript">
            alert('Welcome');
        </script>
    </header>
    <body>
        <table border="1">
            {% for addr in address_book %}
                <tr><td colspan="2" style="text-align:center;"><h4><i>{{ loop.count }}# {{ addr.name }}</i></h4></td></tr>
                <tr><td colspan="2" style='text-align:center;'><b><i>[Professional]</i></b></td></tr>
                <tr><td>Firstname</td><td>{{ addr.name.0 }}</td></tr>
                <tr><td>Lastname</td><td>{{ addr.name.1 }}</td></tr>
                <tr><td>Place</td><td>{{ addr.place }}</td></tr>
                <tr><td>Phone</td><td>{{ addr.phone }}</td></tr>
                {% if addr.personal %}
                    <tr><td colspan="2" style='text-align:center;'><b><i>[Personal]</i></b></td></tr>
                    <tr><td>Phone</td><td>{{ addr.personal.phone }}</td></tr>
                    <tr><td>Email</td><td>{{ addr.personal.email }}</td></tr>
                {% else %}
                    <!-- optional else block -->
                    <tr><td colspan="2" style='text-align:center;'><b><i>[Personal info not available]</i></b></td></tr>
                {% endif %}
                <tr/>
            {% endfor %}
        </table>
    </body>
</html>
```
when provided with the view data structure as
```tcl
puts [::SimpleTemplater::render "/home/user/templates/ex2.tpl" {
    address_book {
        {
            name {John Doe}
            place {USA}
            phone {001}
            personal {
                phone   "001-123-12345"
                email   "john.doe@e-mail.com"
            }

        }

        {
            name {David Beck}
            place {England}
            phone {002}
            personal {}
        }

        {
            name "Sam Philip"
            place {Australia}
            phone {003}
            personal "[list \
                phone   "007-134-4567" \
                email   "sam.philip@e-mail.com" \
            ]"
        }
    }
}]
```    
into 
```html
<html>
    <header>
        <script type="text/javascript">
            alert('Welcome');
        </script>
    </header>
    <body>
        <table border="1">
                <tr><td colspan="2" style="text-align:center;"><h4><i>1# John Doe</i></h4></td></tr>
                <tr><td colspan="2" style='text-align:center;'><b><i>[Professional]</i></b></td></tr>
                <tr><td>Firstname</td><td>John</td></tr>
                <tr><td>Lastname</td><td>Doe</td></tr>
                <tr><td>Place</td><td>USA</td></tr>
                <tr><td>Phone</td><td>001</td></tr>                
                    <tr><td colspan="2" style='text-align:center;'><b><i>[Personal]</i></b></td></tr>
                    <tr><td>Phone</td><td>001-123-12345</td></tr>
                    <tr><td>Email</td><td>john.doe@e-mail.com</td></tr>
                <tr/>
                <tr><td colspan="2" style="text-align:center;"><h4><i>2# David Beck</i></h4></td></tr>
                <tr><td colspan="2" style='text-align:center;'><b><i>[Professional]</i></b></td></tr>
                <tr><td>Firstname</td><td>David</td></tr>
                <tr><td>Lastname</td><td>Beck</td></tr>
                <tr><td>Place</td><td>England</td></tr>
                <tr><td>Phone</td><td>002</td></tr>                
                    <!-- optional else block -->
                    <tr><td colspan="2" style='text-align:center;'><b><i>[Personal info not available]</i></b></td></tr>
                <tr/>
                <tr><td colspan="2" style="text-align:center;"><h4><i>3# Sam Philip</i></h4></td></tr>
                <tr><td colspan="2" style='text-align:center;'><b><i>[Professional]</i></b></td></tr>
                <tr><td>Firstname</td><td>Sam</td></tr>
                <tr><td>Lastname</td><td>Philip</td></tr>
                <tr><td>Place</td><td>Australia</td></tr>
                <tr><td>Phone</td><td>003</td></tr>                
                    <tr><td colspan="2" style='text-align:center;'><b><i>[Personal]</i></b></td></tr>
                    <tr><td>Phone</td><td>007-134-4567</td></tr>
                    <tr><td>Email</td><td>sam.philip@e-mail.com</td></tr>
                <tr/>
        </table>
    </body>
</html>
```
## Syntax
```tcl
::SimpleTemplater::render "<template_path>" "<view>"
```
## Usage
```tcl
source <file_path>/SimpleTemplater.tcl
puts [::SimpleTemplater::render "<template_path>" {
    <[Template Object_Name]>    <[TCL_Variable|String]>
}]
```
#### Pre-compiled templates for faster executions
```tcl
source <file_path>/SimpleTemplater.tcl
set my_template [::SimpleTemplater::compile "<template_path>"]
puts [$my_template execute {
    <[Template Object_Name]>    <[TCL_Variable|String]>
}]
```
### Template language
#### Simple variables
#####`View`
``` 
{
    name {John}
}
```
#####`Template`
```
<p>Hello {{name}}</p>
```
#####`Output`
```
<p>Hello John</p>
```
#### Nested data structures
#####`View`
```
{
    address {
        {
            name {John Doe}
        }
        
        {
            name {Philip Alex}
        }
    }
}
```
#####`Template`
```
{% for addr in address %}
   <p>{{loop.count}} Firstname: {{addr.name.0}}</p>
{% endfor %}
```
#####`Output`
```
<p>1 Firstname: John</p>
<p>2 Firstname: Philip</p>
```
*A list element can be accessed by providing the numeric index `{{ context_var.index }}` and a key-value dictionary styled list element can be accessed providing the key as the index `{{ context_var.key }}`*
### For loop syntax
#### Single iterator
#####`View`
```
{
    players {
    	{Rafael Nadal}
    	{Roger Federer}
    }
}
```
#####`Template`
```html
{% for person in players %}
<p>{{person}}</p>
{% endfor %}
```
#####`Output`
```html
<p>Rafael Nadal</p>
<p>Roger Federer</p>
```
#### Multi-iterator
#####`View`
```
{
    players {
    	{Rafael Nadal}
    	{Roger Federer}
    	{Novak Djokovic}
    	{Andy Murray}
    }
}
```
#####`Template`
```html
{% for person1, person2 in players %}
<p>{{person1}}, {{person2}}</p>
{% endfor %}
```
#####`Output`
```html
<p>Rafael Nadal, Roger Federer</p>
<p>Novak Djokovic, Andy Murray</p>
```
#### Iterating simple static data
#####`Template`
```html
{% for a in "hello world" %}
<p>{{a}}</p> <!-- first hello second world -->
{% endfor %}
```
#####`Output`
```html
<p>hello</p>
<p>world</p>
```
#### Inbuit loop counter
#####`View`
```
{
    players {
    	{Rafael Nadal}
    	{Roger Federer}
    }
}
```
#####`Template`
```html
{% for person in players %}
<p>{{ loop.count }}. {{ person }}</p>
{% endfor %}
```
#####`Output`
```html
<p>1. Rafael Nadal</p>
<p>2. Roger Federer</p>
```
### If loop syntax
##### If loop supports the operators `(in < > <= >= ni == !=)`
#####`View`
```
{
    name {John John}
}
```
#####`Template`
```html
{% if name.0 == name.1 %}
<p>You have an interesting name!</p>
{% endif %}
```
#####`Output`
```html
<p>You have an interesting name!</p>
```

```html
{% if name.0 == "John" %}
 <!-- do something -->
{% endif %}
```
#### Optional else block
```html
{% if name.0 == "John" %}
 <!-- do something -->
{% else %}
 <!-- do something else-->
{% endif %} 
```
#### Truthiness check
```html
{% if not name %}
 <!-- do something -->
{% endif %}
<!-- OR -->
{% if !name %}
 <!-- do something -->
{% endif %}
```
#####`View`
```
{
    members {
    	{
    		active 1
    		name "John Doe"
    	}
    	{
    		active 0
    		name "Philip Alex"
    	}
    }
}
```
#####`Template`
```html
Active members:
<table>
{% for mem in members %}
	{% if mem.active %}
		<tr><td>{{ mem.name }}</td></tr>
	{% endif %}
{% endfor %}
</table>

Inactive members:
<table>
{% for mem in members %}
    {% if not mem.active %}
        <tr><td>{{ mem.name }}</td></tr>
    {% endif %}
{% endfor %}
</table>
```
#####`Output`
```html
Active members:
<table>
		<tr><td>John Doe</td></tr>
</table>
Inactive members:
<table>
		<tr><td>Philip Alex</td></tr>
</table>
```
## Auto-escaping
Any variable used within the template would be auto-escaped.
Consider an email id of a person saved as 
```javascript
<script type="text/javascript">alert('XSS');</script>
```
would make your site vulnerable to XSS.
SimpleTemplater would automatically get all your variables escaped
```html
<tr><td>Email</td><td>{{ addr.personal.email }}</td></tr>
```
into
```html
<tr><td>Email</td><td>&lt;script type=&quot;text/javascript&quot;&gt;alert(&#39;XSS&#39;);&lt;/script&gt;</td></tr>
```
instead of
```html
<tr><td>Email</td><td><script type="text/javascript">alert('XSS');</script></td></tr>
```
You can explicitly mark a variable not to be escaped by applying a safe filter (filters mentioned below)
```html
<tr><td>Email</td><td>{{ addr.personal.email|safe }}</td></tr>
```

## Filters
### Inbuilt Filters
Usage: `{{ context_var|<filter> }}`
#### safe
`{{ context_var|safe }}` prevents your variable from being auto-escaped
#### tick
`{{ context_var|tick }}` converts all `'` in your variable to `´` after escaping

### Custom Filters
Create a new transformation procedure
```tcl
proc Modulus { context args } {
    return [expr { $context % [lindex $args 0] }]
}
```

Register the filter in your script
```tcl
::SimpleTemplater::registerFilter -filter modulus -proc Modulus
# optional -safe true|false
```
Syntax: `::SimpleTemplater::registerFilter -filter <filter_name> -safe <true|false> -proc <procedure_name>`

Apply the filter in your template
`{{ index|modulus:"10" }}`

#### Example using chained filters
View
```tcl
proc Modulus { context args } {
    if { ![regexp {^\d+$} [lindex $args 0]] } { return 0 }
	return [expr { $context % [lindex $args 0] }]
}

proc Class { context args } {
	return [lindex $args $context]
}

::SimpleTemplater::registerFilter -filter modulus -proc Modulus
::SimpleTemplater::registerFilter -filter class   -proc Class

puts [::SimpleTemplater::render "/home/user/templates/sample.tpl" {
    example {
        .... ....
    }
}]
```

Template
```
{% for ex in example %}
...
 <tr class="{{loop.count|modulus:"2"|class:"grey,white"}}">..</tr>
...
{% endfor %}
```

Output
```html
...
 <tr class="white">..</tr>
 <tr class="grey">..</tr>
 <tr class="white">..</tr>
 <tr class="grey">..</tr>
 <tr class="white">..</tr>
...
```
