import IndexPage from './index.po'

describe('Index page', () => {
  let page

  beforeEach(() => {
    page = new IndexPage()
  })

  it('should display welcome message', () => {
    page.navigateTo()
    expect(page.contentText).toBe('Hello Next.js')
  })
})
