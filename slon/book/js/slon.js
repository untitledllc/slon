function willRotate(rotateTo){
    if('landscape' == rotateTo){
        $(".page").removeClass('portrait').addClass('landscape');
        $("#arrowleft").removeClass('portrait').addClass('landscape');
        $("#arrowright").removeClass('portrait').addClass('landscape');
        $("#carousel").removeClass('portrait').addClass('landscape');
        $("#euroman").removeClass('portrait').addClass('landscape');
    } else {
        $(".page").removeClass('landscape').addClass('portrait');
        $("#arrowleft").removeClass('landscape').addClass('portrait');
        $("#arrowright").removeClass('landscape').addClass('portrait');
        $("#carousel").removeClass('landscape').addClass('portrait');
        $("#euroman").removeClass('landscape').addClass('portrait');
    }
}

function ProtateWithParam(page, toOrientation){
    $('.page').css('display', 'none');
    $('#page_'+page).css('display', 'block');
    if('landscape' == toOrientation){
        $("#root").removeClass('portrait').addClass('landscape');
        $(".page").removeClass('portrait').addClass('landscape');
    } else {
        $("#root").removeClass('landscape').addClass('portrait');
        $(".page").removeClass('landscape').addClass('portrait');
    }
}

function loadOrientation(){
    var width = document.body.clientWidth;
    if (width > 768) {
        willRotate('landscape');
    } else {
        willRotate('portrait');
    }
}

(function($) {
  var cache = [];
  $.preLoadImages = function() {
  var args_len = arguments.length;
  for (var i = args_len; i--;) {
  var cacheImage = document.createElement('img');
  cacheImage.src = arguments[i];
  cache.push(cacheImage);
  }
  }
  })(jQuery)