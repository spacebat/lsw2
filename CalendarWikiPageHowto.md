# Instructions #

  * **In Google Calendar:**
    * Go to Calendar Settings for the calendar
    * Under Share this Calendar, check the box to Make this calendar public
    * Go to Calendar Details
    * Under Embed this Calendar, click on Customize the color, size, and other options
    * Set the Default View to Agenda, make other desired changes
    * Copy the url in the src of the iframe (e.g. `https://www.google.com/calendar/embed?mode=AGENDA&amp;height=600&amp;wkst=1&amp;bgcolor=%23FFFFFF&amp;src=n9u9oasakfdhv0nmedn718q1hc%40group.calendar.google.com&amp;color=%235229A3&amp;ctz=America%2FNew_York`)


  * Create an XML file for your calendar Gadget, pasting the url from the last step above into the Content href:
```
<Module>
  <ModulePrefs
      author_email="youremail@example.com"
      height="400"
      title_url="http://www.example.com"
      description="put a description here"
      author_link="http://www.example.com"
      title="A Title"
      author="Your Name"/>
<Content type="url" 
  href="https://www.google.com/calendar/embed?mode=AGENDA&amp;height=600&amp;wkst=1&amp;bgcolor=%23FFFFFF&amp;src=n9u9oasakfdhv0nmedn718q1hc%40group.calendar.google.com&amp;color=%235229A3&amp;ctz=America%2FNew_York" 
/>

</Module>
```

  * Save this file in an accessible place, e.g. `http://example.com/my-example-calendar-gadget.xml`

  * Edit your wiki page, adding a wiki:gadget whose url is the url of the XML file you created above:

`<wiki:gadget url="http://example.com/my-example-calendar-gadget.xml" height="400" width="600" border="0" />`

  * Save or preview the wiki page. The agenda view of the calendar should appear.

# Example wiki page with calendar #
  * [Calendar Test Page](https://code.google.com/p/lsw2/wiki/CalendarTestPage)