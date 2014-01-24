'use strict';
/* jshint undef: true, unused: true */
/*global $:false */
/*global Modernizr */


$( document ).ready(function() {
  var drsApp = (function() {
   
      var init = function( settings ) {
          drsApp.config = {
              $drsBootstrapSelect: $( 'select.bs-select' ),
              $addToSetLink: $('#addToSet'),
              breadCrumbMenuContent: $('#addToSetLinks').html(),
              fitTextTarget: $('.fit-text')
          };
   
          // allow overriding the default config
          $.extend( drsApp.config, settings );
   
          setup();
      },
   
      setup = function() {
          nuCollectionsPage();
          drsApp.config.$drsBootstrapSelect.selectpicker();
          breadCrumbMenu();
          handleFitText();
          tooltipSetup();
          handleRequiredInputs();
          ellipsisExpand();
          drsToggleView();
          handleDrsCommunities();
          handleDrsAdminCommunities();
          handleCommunitiesAdminAutoComplete();

          toggleShoppingCart($('*[data-shoppingcart]'));
          handleDrsItem($('.drs-item[data-drsitem]:not(.drs-item-full)')); 
          
          
          
      },
      /**
       * Provides the breadcrumb popover menu for adding collections or new items to the application.
       */
      breadCrumbMenu = function(){
          drsApp.config.$addToSetLink.popover({
              html: true,
              content: drsApp.config.breadCrumbMenuContent,
          }).on('shown', function(){
            $(this).parent('li').addClass('active');
          }).on('hide', function(){
            $(this).parent('li').removeClass('active');
          });
      },

      addToComplationLink =  function(e){
        e.on('ajax:success', function( ){
          var delta = $(this).data('method');
          switch(delta){
            case'post':
              $(this)
                .text($(this).text().replace('Add to', 'Remove from'))
                .data('method', 'delete')
                .removeClass('btn-success add-to-compilation')
                .addClass('btn-danger remove-from-compilation');
            break;
            case 'delete':
                $(this)
                .data('method', 'post')
                .text($(this).text().replace('Remove from', 'Add to' ))
                .addClass('btn-success add-to-compilation')
                .removeClass('btn-danger remove-from-compilation');
            break;
            default:
              console.log('ajax successful, but not sure what to do!');
            break;
          }
          
        }).on('ajax:error', function(){
          $(this).closest('.modal').modal('hide');
           $('.breadcrumb').addBsAlert({
            classes: 'alert alert-danger',
            strong: 'Error,',
            text: 'Something went wrong, please reload the page and try again.',
           });

        });
      },
      newCompilationForm =  function(){
        $('#new_compilation').on('ajax:success', function(){
          $(this).closest('.modal').modal('hide');
           
           $('.breadcrumb').addBsAlert({
            classes: 'alert alert-success',
            strong: 'Success!',
            text: 'You created a new compilation!',
           });

        }).on('ajax:error', function(){
          $(this).closest('.modal').modal('hide');
           $('.breadcrumb').addBsAlert({
            classes: 'alert alert-danger',
            strong: 'Error,',
            text: 'Something went wrong, please reload the page and try again.',
           });

        });
      },
      compilationsModal =  function(e){
        var $modal = $('#ajax-modal');
          
        $modal.empty().append(e).modal('show');
        
        $modal.on('hidden', function(){
          $(this).empty();
        });
        
        drsApp.addToComplationLink($('.btn-compilation'));
        drsApp.newCompilationForm();
      },
      /**
       * Checks the dom to see if the plugin target is there and then loads it with Modernizr
       */
      handleFitText = function(){
        if (drsApp.config.fitTextTarget.length > 0 && window.Modernizr){
          Modernizr.load({
            load: '//cdnjs.cloudflare.com/ajax/libs/FitText.js/1.1/jquery.fittext.min.js',
             complete: function () {
                if ( !$.fitText ) {
                    Modernizr.load('/assets/polyfills/FitText-js/jquery.fittext.js');
                }
                drsApp.config.fitTextTarget.fitText();
              }
          });
        }


      },
      /**
       * Tooltip Setup
       */
      tooltipSetup =  function(){
        $('body').tooltip({
            selector: 'a[data-toggle=tooltip]'
          });
      },

      /**
       * Builds interaction to inputs with [required="required"] to make sure that the user fills it out.
       */
      handleRequiredInputs = function(){
        //Query for inputs textareas and selects with require
        var targets = $('input, textarea, select').filter('[required="required"]');
        //Construct the tooltips for inputs that need to be filled still.
        var addTooltip = function(e){
          return $(e).tooltip({
            title: 'Required'
          });
        };
        //cycle through each function.
        targets.each(function(index, el) {
          
          var id = $(el).attr('id');
          //add the required class.
          $('label[for="' + id +'"]').addClass('required-label');
          
          // Check the element to figure out if we still need the tooltip or not.
          
          $(el).on('focus hover click change keypress', function(){
            if($(this).val().length > 0 ){
              $(this).tooltip('destroy');
            }else{
              addTooltip(this);
            }
          });
        });
      },
      /**
       * Looks for the datatoggle
       * @return {[type]} [description]
       */
      ellipsisExpand = function(){
        var $toggleLink = $('*[data-toggle="ellipsis"]');

        //look for the target and toggle classes on that element.
        var toggleState = function(event){
          //stop the event from triggering other reations
          event.preventDefault();
          event.stopPropagation();
          var $target = $(this).attr('href').length > 0 ? $($(this).attr('href')) : $($(this).data('target'));
          if ($target.length > 0 ){
            if ( ! $target.hasClass('ellipsis') ){
              $target = $target.find('.ellipsis');
            }
            $target.toggleClass('in');
            $(this).children('i').toggleClass('icon-expand-alt').toggleClass('icon-collapse-alt');
          }else{
            console.log('Invalid target specified for drsApp.ellipsisExpand' , $target);
          }
        };
      $toggleLink.on('click', toggleState );
        
      };
      /**
       * drsToggleView adds an event listener to a div containing two buttons that should toggle a class on an conainter div with drs-items to change their display.
       * 
       */
      var drsToggleView = function(){
       var handleClick = function(event){
        event.preventDefault();
        event.stopPropagation();
        var toggleContainer = $(this).closest('*[data-container]');
        var container = $( toggleContainer.data('container') );
        var desiredClass = $(this).data('target');
        if (container.hasClass(desiredClass)){
          event.preventDefault();
        }else{
          
          container.find('.drs-item').removeClass('active');
          toggleContainer.find('a, button').removeClass('active');
          $(this).addClass('active');
           
          if (desiredClass === 'drs-items-grid' ){
            container.removeClass('drs-items-list').addClass('drs-items-grid');
          }else{
            container.removeClass('drs-items-grid').addClass('drs-items-list');

          }
          if($('body').data('user') > 0 ){
            updateUserViewPref($(this));  
          }else{
            storeData({

            });
            
          }
          

        }
        
        
       };
       $('[data-toggle="drs-item-views-radio"]').on('click', 'a , button', handleClick);

      };

      var storeData = function ( data ){
        var storage = window.localStorage;
        var storedData;
        if ( storage.key( 'drsApp' )){
          storedData = storage.getItem( 'drsApp' );
          storedData = JSON.parse( storeData );
          data = $.merge( storedData, data );
          
        }
        storage.setItem( 'drsApp' , JSON.stringify ( data ) );
      };

      fetchData = function( ){

        var data = {};


        if( window.localStorage ){
          if ( window.localStorage.('dr')){
            data JSON.parse( window.localStorage.getItem('drsApp') )
          }
        }

      };
      var getData = function ( key ){
         var storage = window.localStorage;
         var storedData = JSON.parse( storage.getItem ;

      };

      var gridOrListSwitch = function(dataTarget){
        switch(dataTarget){
          case 'drs-items-list':
            return 'list';
          case 'drs-items-grid':
            return 'grid';
          default:
            throw 'dataTarget wasn\'t given';
        }

      };
      /**
       * updateUserViewPref
       * @TODO
       */
      var updateUserViewPref = function(element){
        if( drsApp.config.updateUserviewPrefBoolean ){
          var target = element.data('target');
          var userId = $('body').data('user') || 5;
          var queryString = '/users/'+ userId;
          $.ajax({
           'url' : queryString,
           'type': 'post',
           'data' : {
            'view_pref': gridOrListSwitch(target)
            },
            'complete': function( jqXHR,textStatus){
              
            }
           });
        }
      };




      //Handles spawning new permission related form elements on the nu_collections/new page. 
      var nuCollectionsPage = function(){
        //Add a datepicker to the date of issuance field. 
        $('#date-issued, #embargo-date').datepicker({
          todayBtn: true,
          todayHighlight: true,
          clearBtn: true
        });

        // Adding the form fields behavior to the buttons on the nu collections.
        $('#add_another_personal_creator').addFormFields({
          target: $('div.personal_creator'),
          titleText: "Remove Personal Creator"
        });

        
        $('#add_another_corporate_creator').addFormFields({
          target: $('div.corporate_creator'),
          titleText: "Remove Corporate Creator",
        });  


        $('#add_another_keyword').addFormFields({
          target: $('div.keyword'),
          titleText:  "Remove keyword"
        });
        $('#add_another_permission').addFormFields({
          target: $('div.permission'),
          titleText: "Remove permission"
        });
      };
      var handleDrsCommunities = function(){
        if ($("#community_autocomplete").length > 0) { 
          $("#community_autocomplete").autocomplete({
              source: communities_for_autocomplete,
              select: function(e, ui) {
                  e.preventDefault() // <--- Prevent the value from being inserted.
                  $("#community_parent").val(ui.item.value);
                  $(this).val(ui.item.label);
              },
              focus: function( e, ui ) {
                e.preventDefault() // <--- Prevent the value from being inserted.
              }
          });

          $( "#community_autocomplete" ).attr('autocomplete', 'on');
        }
      };


      var handleDrsAdminCommunities = function(){
        if ($("#admin_community_autocomplete").length > 0) { 
          $("#admin_community_autocomplete").autocomplete({
              source: communities_for_employee_autocomplete,
              select: function(e, ui) {
                  e.preventDefault() // <--- Prevent the value from being inserted.
                  $("#admin_community").val(ui.item.value);
                  $(this).val(ui.item.label);
              },
              focus: function( e, ui ) {
                e.preventDefault() // <--- Prevent the value from being inserted.
              }
          });

          $( "#admin_community_autocomplete" ).attr('autocomplete', 'on');
        }
      };
      var handleCommunitiesAdminAutoComplete = function(){
        if ($("#admin_employee_autocomplete").length > 0) { 
          $("#admin_employee_autocomplete").autocomplete({
              source: employees_for_autocomplete,
              select: function(e, ui) {
                  e.preventDefault() // <--- Prevent the value from being inserted.
                  $("#admin_employee").val(ui.item.value);
                  $(this).val(ui.item.label);
              },
              focus: function( e, ui ) {
                e.preventDefault() // <--- Prevent the value from being inserted.
              }
          });

          $( "#admin_employee_autocomplete" ).attr('autocomplete', 'on');
        }

      };
      var handleDrsItem = function(element){
        
        $(element).on('click' ,function( event ){
          var target = $( event.target );
          
          var parent = $( this ).closest( '.drs-items' );
          if ( target.is('a, a*, button, button * , input, input *,  select, select *, textarea')){
            event.stopPropagation();
            
          }else if( parent.data('toggle') === 'drs-view' ){
            //remove add the class to the target.
            if( $(this).hasClass('active') ){
              parent.find('.drs-item').removeClass('active');
             
            }else{
              parent.find('.drs-item').removeClass('active');
              $(this).addClass('active');
              
            }
            
            pictureActive($(this).find('[data-picture]'));


          }else if( $( this ).data( 'href' ).length > 4 && !$(this).hasClass('drs-item-full') ) {

            window.location.assign( $(this).data('href') );
          }

          
        });
      };

      var pictureActive = function(element){
        var $e = $(element);
        var $src = $e.find('[data-src]');
        
        
        $src.each( function( ){

          var $this = $(this);
          if ( !$this.attr('data-media') ){
            $this.attr({
              'data-media' : ' '
            });
          }
          var target = $this.attr('data-active');
          var active = $this.attr('data-media');
          
          $this.attr({ 
            'data-media': target,
            'data-active': active,
          });

        });


        picturefill.apply();
      };

      var cloneGrid = function( t, parent){
        console.log($('.drs-item').length);

        var $t = $(t);
        
        $(parent).find('.drs-item.jumbotron').remove();
        
        if ( $t.hasClass('active') ){
          var $clone =  $t.clone();
          $clone.addClass('jumbotron');
          $t.append($clone); 


          
        }
           
      
        
      };

      /**
       * Listener function for shopping cart links with a fall back on failure to reload the page.
       */

      var toggleShoppingCart = function(e){
        var $e = $(e)
        if($e.length > 0 ){
          $e.on('ajax:beforeSend', function(){
            $(this).attr('data-shoppingcart', 'replace');
            $(this).tooltip('destroy');
          }).on('ajax:failure', function(){
            
            window.location.reload();
          }).on('ajax:success', function(){
            toggleShoppingCart(drsApp.$new);
            $(this).replaceWith(drsApp.$new);
            drsApp.$new = null;
          });
        }
      };



      // these are the public API
      return{
        init: init,
        addToComplationLink: addToComplationLink,
        newCompilationForm: newCompilationForm,
        compilationsModal: compilationsModal
      };

   
  })();
  //end drsApp module;
  
  window.drsApp = drsApp;
  drsApp.init({
    updateUserviewPrefBoolean: false,
  });
});
 

