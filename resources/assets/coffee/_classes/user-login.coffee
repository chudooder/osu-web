###
# Copyright 2015-2016 ppy Pty. Ltd.
#
# This file is part of osu!web. osu!web is distributed with the hope of
# attracting more community contributions to the core ecosystem of osu!.
#
# osu!web is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License version 3
# as published by the Free Software Foundation.
#
# osu!web is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with osu!web.  If not, see <http://www.gnu.org/licenses/>.
###
class @UserLogin
  clickAfterLogin: null # Used as callback on original action (where login was required)


  constructor: (@nav) ->
    $(document).on 'ajax:success', '.js-login-form', @loginSuccess
    $(document).on 'ajax:error', '.js-login-form', @loginError

    $(document).on 'click', '.js-user-link', @showOnClick
    $(document).on 'click', '.js-login-required--click', @showToContinue

    $(document).on 'ajax:error', @showOnError
    $(document).on 'ready turbolinks:load', @showOnLoad
    $.subscribe 'nav:popup:hidden', @reset


  loginError: (e, xhr) =>
    e.preventDefault()
    e.stopPropagation()
    $('.js-login-form--error').text(osu.xhrErrorMessage(xhr))


  loginSuccess: (_event, data) =>
    $('.js-user-header').html data.header
    $('.js-user-header-popup').html data.header_popup
    $.publish 'user:update', data.user.data
    @nav.hidePopup()
    osu.pageChange()

    Turbolinks.clearCache()
    $(document).off '.ujsHideLoadingOverlay'
    LoadingOverlay.show()
    if @clickAfterLogin?
      if @clickAfterLogin.submit
        # plain javascript here doesn't trigger submit events
        # which means jquery-ujs handler won't be triggered
        # reference: https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit
        $(@clickAfterLogin).submit()
      else if @clickAfterLogin.click
        # inversely, using jquery here won't actually click the thing
        # reference: https://github.com/jquery/jquery/blob/f5aa89af7029ae6b9203c2d3e551a8554a0b4b89/src/event.js#L586
        @clickAfterLogin.click()
    else
      osu.reloadPage()


  reset: =>
    @clickAfterLogin = null


  show: (target) =>
    @clickAfterLogin = target

    @nav.setMode mode: 'user'
    @nav.showPopup()


  showOnClick: (e) =>
    e.currentTarget.dataset.navMode ?= 'user'
    @nav.toggleMenu e


  showOnError: (e, xhr) =>
    return unless xhr.status == 401
    @show e.target


  # for pages which require authentication
  # and being visited directly from outside
  showOnLoad: =>
      return unless window.showLoginModal?

      window.showLoginModal = null
      @show()


  showToContinue: (e) =>
    return if currentUser.id?
    e.preventDefault()
    Timeout.set 0, => @show e.target
