export default class IndexPage {
  navigateTo () {
    browser.url('/')
  }

  get contentText () {
    return $('div p').getText()
  }
}
