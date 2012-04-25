$(document).ready(function(){
    var Tevent = "touchstart";

    $('.page').delegate('.btn', Tevent, function(event){
        var num = $(this).attr('class').slice(8,9);
        $('.page').find('.block').hide();
        $('.block-' + num ).show().animate({
            opacity:1
        },150);
    });
    $('.page').delegate('.close', Tevent, function(event){
        $(this).parent('.block').animate({
            opacity:0
        },150, function(){
            $(this).hide();
        });
    });
    var i = 0;
    function runGallery(item){
        var wrapper = $('.gallery-wrap'),
            step = 702,
            gall = wrapper.find('.gallery'),
            count = gall.find('li').size();

        i=item;

        if(i < count && i > 1){
            $('.arr-btn-right').show();
            $('.arr-btn-left').show();
        }

        $('.gallery-preview').hide();
        wrapper.find('.gallery').css({
            'margin-left':-(item -1)*702 + 'px'
        })
        wrapper.show().animate({
            opacity:1
        },200)

        wrapper.delegate('.close-gall', Tevent, function(){
            wrapper.hide();
            $('.gallery-preview').show();
            wrapper.find('.gallery').css({
                'margin-left':0
            })
        })



        if(i == 1){
            //$('.arr-btn-left').hide();
        }
        else if (i == count){
            //$('.arr-btn-right').hide();
        }
        var animated = true;
        wrapper.find('.arr-btn-right').unbind(Tevent).bind(Tevent, function(){

            if(animated){
                var cur_step = parseInt(gall.css('margin-left'));
                    animated = false;
                $('.arr-btn-left').show();
                gall.animate({
                    'margin-left':cur_step - step
                },200, function(){
                    i++;
                    animated = true;
                    if(i == count){
                        $('.arr-btn-right').hide();
                    }
                })
                }
            })

        wrapper.find('.arr-btn-left').unbind(Tevent).bind(Tevent, function(){
            if(animated){
                var cur_step = parseInt(gall.css('margin-left'));
                    animated = false;
                $('.arr-btn-right').show();

                gall.animate({
                    'margin-left':cur_step + step
                },200, function(){
                    animated = true;
                    i--;
                    if(i == 1){
                        $('.arr-btn-left').hide();
                    }
                })
            }
        })
    }

    $('.page').delegate('.gal-prev-item', Tevent, function(){
        var num = $(this).find('img').attr('name')
        runGallery(num);
    })
    $('.page').delegate('.vsm-about-1', Tevent, function(){
        $('.about-vsm').find('a').removeClass('act')
        $(this).find('a').addClass('act');
        $('.vsm-1').hide();
        $('.vsm-2').show();
        return false;
    })
    $('.page').delegate('.vsm-about-2', Tevent, function(){
        $('.about-vsm').find('a').removeClass('act')
        $(this).find('a').addClass('act');
        $('.vsm-2').hide();
        $('.vsm-1').show();
        return false;
    })
    $('.vsm-1').delegate('.close', Tevent, function(){
        $('.vsm-v-2').removeClass('vsm-v-2');
        $('.vsm-1').hide();
    })
    $('.vsm-2').delegate('.close', Tevent, function(){
        $('.vsm-v-1').removeClass('vsm-v-1');
        $('.vsm-2').hide();
    })
    $("#rjd").bind('ended', function(){
        $("#rjd").hide()
    })
    $('.video-rgd').bind(Tevent, function(){
        var rjdVideo = document.getElementById("rjd");
        var width = document.body.clientWidth;
        if(width > 768){
            $("#rjd").show();
            $(".skip").show();
            rjdVideo.load();
            rjdVideo.play();
        }
    })
    $('.skip').bind(Tevent, function(){
        var rjdVideo = document.getElementById("rjd");
        $("#rjd").hide();
        rjdVideo.pause();
        rjdVideo.load();
    })
});