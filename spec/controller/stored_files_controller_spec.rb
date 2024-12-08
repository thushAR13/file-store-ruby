require 'rails_helper'

describe StoredFilesController, type: :controller do
  let!(:file) { fixture_file_upload('test_file.txt', 'text/plain') }
  let!(:file_hash) { Digest::SHA256.file(file.tempfile).hexdigest }
  let!(:stored_file) { StoredFile.create!(name: 'test_file.txt', file_hash: file_hash).tap { |sf| sf.file.attach(file) } }

  describe 'GET #index' do
    it 'returns all stored files' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end

  describe 'POST #create' do
    context 'when file is uploaded' do
      it 'creates a new stored file' do
        new_file = fixture_file_upload('new_file.txt', 'text/plain')
        post :create, params: { file: new_file }

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['file_hash']).to eq(Digest::SHA256.file(new_file.tempfile).hexdigest)
      end
    end

    context 'when file hash is provided' do
      it 'creates a new entry for an existing file' do
        post :create, params: { file_hash: stored_file.file_hash, name: 'duplicate_file.txt' }

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['message']).to eq('File already exists. New entry created with existing content.')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the stored file' do
      delete :destroy, params: { name: stored_file.name }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to eq('File deleted successfully')
      expect(StoredFile.find_by(name: stored_file.name)).to be_nil
    end
  end

  describe 'GET #word_count' do
    it 'returns the total word count across all files' do
      get :word_count

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['total_words']).to eq(stored_file.file.download.split.size)
    end
  end

  describe 'GET #freq_words' do
    it 'returns the most frequent words across all files in descending order' do
      get :freq_words, params: { limit: 5, order: 'desc' }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).keys.size).to eq(1)
    end

    it 'returns the most frequent words across all files in ascending order' do
      get :freq_words, params: { limit: 5, order: 'asc' }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).keys.size).to eq(1)
    end
  end

  describe 'GET #check_hash' do
    it 'returns true if the file hash exists' do
      get :check_hash, params: { file_hash: stored_file.file_hash }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['match']).to be_truthy
    end

    it 'returns false if the file hash does not exist' do
      get :check_hash, params: { file_hash: 'nonexistenthash' }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['match']).to be_falsey
    end
  end
end
