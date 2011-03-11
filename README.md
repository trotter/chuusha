Chuusha (pronounced chew-sha) is a Rack adapter that treats your css and
javascript files as erb templates. It also provides a basic facility for
sharing constants between all your templates and the rest of your Rack stack.
It will continually evaluate templates in dev mode, while caching the rendered
template in production. It plays nicely with Rails's asset caching.

Installation and Usage
----------------------

First install the gem:

    $ gem install chuusha

Next, require the gem and tell your rack application to use chuusha. You will
need to point it at the directory containing your public assets.

    # in ./config.ru
    require 'chuusha'

    use Chuusha::Rack, File.dirname(__FILE__) + '/public'
    run Rack::URLMap.new("/" => YOUR_RAILS_APP::Application)

Now place a css erb template somewhere in '/public/stylesheets'

    # in ./public/stylesheets/application.css.erb

    <% highlight_color = "#fc6666" %>

    p.highlight {
      color: <%= highlight_color %>;
    }

    div.highlight {
      border: 1px solid <%= highlight_color %>;
    }

Common Variables
----------------

Occasionally, you'll want to share variables amongst many templates. To do so,
pass a hash of variables to Chuusha like so:

    use Chuusha::Rack,
        File.dirname(__FILE__) + '/public',
        { "variables" => { "highlight_color" => "#fc6666" }}

This would add `highlight_color` as a variable in both your css and js erb
templates.

On Heroku
---------

Since Heroku won't allow you write to the file system, you'll have to tell
Chuusha to write to /tmp. This is done by passing an output directory to
Chuusha like so:

    use Chuusha::Rack,
        File.dirname(__FILE__) + '/public',
        nil,
        File.dirname(__FILE__) + '/tmp'

Bugs
----

Chuusha is still pretty young and probably has bugs. Feel free to email me
(Trotter Cashion) at cashion@gmail.com if you find anything. Alternately, you
can tweet me at @cashion, as I often respond more quickly to public humiliation
:-).

Acknowledgements
----------------

Thanks to [Mat Schaffer](http://matschaffer.com) for the name.


