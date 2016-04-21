require_relative '../../../template_app/lib/search'

describe Bookbinder::Search do
  before do
    allow(Bookbinder::Search).to receive(:search_client) { mock_searcher }
    allow(Bookbinder::Search::Result).to receive(:layout_content) { '<%= yield %>' }
  end

  let(:mock_searcher) { double(:search) }

  it 'shows search results' do
    allow(mock_searcher).to receive(:search) do
      {
        'hits' => {
          'total' => 3,
          'hits' => [
            {
              '_source' => {
                'url' => 'hi.html',
                'title' => 'Hi'
              },
              'highlight' => {
                'text' => [' Im a highlight ']
              }
            },
            {
              '_source' => {
                'url' => 'bye.html',
                'title' => 'Bye'
              },
              'highlight' => {
                'text' => [' Im bye highlight ']
              }
            },
            {
              '_source' => {
                'url' => 'another.html',
                'title' => 'Another'
              },
              'highlight' => {
                'text' => [' Im another highlight ']
              }
            },
          ]
        }
      }
    end

    resulting_page = Bookbinder::Search.call({ 'QUERY_STRING' => 'foo=bar&q=search&baz=quux' })

    expect(resulting_page.last.first).to include('<a href="hi.html">Hi</a>')
    expect(resulting_page.last.first).to include('<div>Im a highlight</div>')
    expect(resulting_page.last.first).to include('Bye')
    expect(resulting_page.last.first).to include('another')

    expect(mock_searcher).to have_received(:search).with({index: 'searching', body: {
      'query' => { 'query_string' => { 'query' => 'search', 'default_field' => 'text' }},
      'from' => 0,
      'size' => 10,
      '_source' => [ 'url', 'title' ], 'highlight' => { 'fields' => { 'text' => { 'type' => 'plain' }}}
    }})
  end

  it 'should show no results if no results were found' do
    allow(mock_searcher).to receive(:search) do
      {
        'hits' => {
          'total' => 0,
          'hits' => []
        }
      }
    end

    resulting_page = Bookbinder::Search.call({ 'QUERY_STRING' => 'foo=nothinghere&q=search&baz=nothinghere' })

    expect(resulting_page.last.first).to include('No Results')
  end

  it 'should show no results for an empty search query' do
    resulting_page = Bookbinder::Search.call({ 'QUERY_STRING' => 'q=' })

    expect(resulting_page.last.first).to include('No Results')
  end

  it 'should show no results for a request with no query' do
    resulting_page = Bookbinder::Search.call({ 'QUERY_STRING' => 'foo=bar' })

    expect(resulting_page.last.first).to include('No Results')
  end

  it 'should get the specified page of results' do
    allow(mock_searcher).to receive(:search) do
      {
        'hits' => {
          'total' => 23,
          'hits' => [
            {
              '_source' => {
                'url' => 'hi.html',
                'title' => 'Hi'
              },
              'highlight' => {
                'text' => [' Im a highlight ']
              }
            },
            {
              '_source' => {
                'url' => 'bye.html',
                'title' => 'Bye'
              },
              'highlight' => {
                'text' => [' Im bye highlight ']
              }
            },
            {
              '_source' => {
                'url' => 'another.html',
                'title' => 'Another'
              },
              'highlight' => {
                'text' => [' Im another highlight ']
              }
            },
          ]
        }
      }
    end
    resulting_page = Bookbinder::Search.call({ 'QUERY_STRING' => 'q=search&page=3' })

    expect(resulting_page.last.first).to include('another')

    expect(mock_searcher).to have_received(:search).with({index: 'searching', body: {
      'query' => { 'query_string' => { 'query' => 'search', 'default_field' => 'text' }},
      'from' => 20,
      'size' => 10,
      '_source' => [ 'url', 'title' ], 'highlight' => { 'fields' => { 'text' => { 'type' => 'plain' }}}
    }})
  end

  describe Bookbinder::Search::Result do
    describe 'page_window' do
      it 'shows a single page' do
        result = Bookbinder::Search::Result.new('', 10, [], 1)

        expect(result.page_window).to eq([1])
      end

      it 'shows the first 5 pages' do
        result = Bookbinder::Search::Result.new('', 100, [], 1)

        expect(result.page_window).to eq([1, 2, 3, 4, 5])
      end

      it 'shows the 5 surrounding pages' do
        result = Bookbinder::Search::Result.new('', 100, [], 5)

        expect(result.page_window).to eq([3, 4, 5, 6, 7])
      end

      it 'shows the last 5 pages on the last page' do
        result = Bookbinder::Search::Result.new('', 100, [], 10)

        expect(result.page_window).to eq([6, 7, 8, 9, 10])
      end

      it 'shows the last 5 pages on the second to last page' do
        result = Bookbinder::Search::Result.new('', 100, [], 9)

        expect(result.page_window).to eq([6, 7, 8, 9, 10])
      end
    end
  end
end