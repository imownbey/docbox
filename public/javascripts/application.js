// Stolen from Evan Weaver's Allison RDoc Template
RegExp.escape = function(text) {
  if (!arguments.callee.sRE) {
    var specials = ['/', '.', '*', '+', '?', '|', '(', ')', '[', ']', '{', '}', '\\'];
    arguments.callee.sRE = new RegExp(
      '(\\' + specials.join('|\\') + ')', 'g'
    );
  }
  return text.replace(arguments.callee.sRE, '\\$1');
}

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
    resetSidebar()
    return false
  })
  
  var sidebarHTML = $('#sidebar-content').html()
  $('#search').keyup(function () {
    if (this.value != this.lastValue) {
      if (this.timer) clearTimeout(this.timer);
      this.timer = setTimeout(function () {
        if($('#search').val() == '') {
          resetSidebar()
        } else {
          $('.toggle').hide()
          $('.clear-button').show()
          searchFor = $('#search').val()
          $('.sidebar ul.methods').hide()
          $('.sidebar ul.methods li').each(function() {
            if($(this).text().match(searchFor)) {
              $(this).parent('ul.methods').show()
            }
          })
        }
      }, 200);
      
      this.lastValue = this.value;
    }
  });
  
  function resetSidebar() {
    $('.clear-button').hide()
    $('#nav-sidebar').children('ul.methods').hide()
    $('.toggle').show()
    checkForArrows()
  }
  
  function checkForArrows() {
    $('.toggle').each(function() {
      if($(this).text() == "↓") {
        $(this).parent().children('.methods').show()
      } else {
        $(this).parent().children('.methods').hide()
      }
    })
  }
  
  $('.toggle').click(function() {
    if($(this).text() == "↓") {
      $(this).text("←")
      $(this).parent().children('.methods').hide()
    } else {
      $(this).text('↓')
      $(this).parent().children('.methods').show()
    }
    return false
  })
});

jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")} 
})