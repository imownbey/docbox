$(document).ready(function () {
  // Versioning
  $('a.version').click(function() {
    url = this.href
    var v1 = ""
    var v2 = ""
    $.get(url, 
      function(data1) {
        $.get(location.href, 
          function(data2) {
            $('.comment').children('.body').html(diffString(data1, data2))
          }
        )
      }
    )

  //  
    return false
  })
  
  // Sidebar Search
  $('.clear-button').click(function() {
    $('#search').val('')
    reshowSidebar()
    return false
  })
  
  var sidebarHTML = $('#sidebar-content').html()
  $('#search').keyup(function () {
    if (this.value != this.lastValue) {
      if (this.timer) clearTimeout(this.timer);
      this.timer = setTimeout(function () {
        if ($("#search").val() == '') {
          reshowSidebar()
        } else {
          $('#sidebar-content').html("<dt>Searching...</dt><dl></dl>")
          $('.clear-button').show()
          $('#sidebar-content').load('/search/results?q=' + $("#search").val())
        }
      }, 200);
      
      this.lastValue = this.value;
    }
  });
  
  function reshowSidebar() {
    $('.clear-button').hide()
    $('#sidebar-content').html(sidebarHTML)
  }
});

jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")} 
})