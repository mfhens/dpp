'use client';

import { useState } from 'react';

export default function UploadPage() {
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [result, setResult] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setFile(e.target.files[0]);
      setResult(null);
      setError(null);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!file) {
      setError('Please select a file');
      return;
    }

    setUploading(true);
    setError(null);
    setResult(null);

    try {
      const formData = new FormData();
      formData.append('file', file);

      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
      const response = await fetch(`${apiUrl}/upload/planning-insights`, {
        method: 'POST',
        body: formData,
      });

      const data = await response.json();

      if (response.ok) {
        setResult(data);
        setFile(null);
        // Reset file input
        const fileInput = document.getElementById('fileInput') as HTMLInputElement;
        if (fileInput) fileInput.value = '';
      } else {
        setError(data.detail || 'Upload failed');
      }
    } catch (err: any) {
      setError(err.message || 'An error occurred');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">📁 Upload Planning Insights</h1>
      
      <div className="max-w-2xl mx-auto">
        <div className="bg-white shadow-md rounded-lg p-6 border-2 border-dashed border-gray-300">
          <p className="text-gray-600 mb-4">
            Upload a CSV file containing planning insights data to update DPPs.
          </p>
          
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <input
                id="fileInput"
                type="file"
                accept=".csv"
                onChange={handleFileChange}
                className="block w-full text-sm text-gray-500
                  file:mr-4 file:py-2 file:px-4
                  file:rounded-md file:border-0
                  file:text-sm file:font-semibold
                  file:bg-blue-50 file:text-blue-700
                  hover:file:bg-blue-100
                  cursor-pointer"
                disabled={uploading}
              />
            </div>

            <button
              type="submit"
              disabled={!file || uploading}
              className="w-full bg-green-600 text-white py-3 px-4 rounded-md
                hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed
                font-semibold transition-colors"
            >
              {uploading ? '⏳ Uploading...' : 'Upload File'}
            </button>
          </form>

          {error && (
            <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-md">
              <p className="text-red-800">❌ {error}</p>
            </div>
          )}

          {result && (
            <div className="mt-4 p-4 bg-green-50 border border-green-200 rounded-md">
              <p className="text-green-800 font-semibold mb-2">✅ Upload Successful!</p>
              <ul className="text-sm text-green-700 space-y-1">
                <li>• File: {result.filename}</li>
                <li>• Records read: {result.records_read}</li>
                <li>• DPPs updated: {result.dpps_updated}</li>
                {result.dpps_not_found > 0 && (
                  <li className="text-yellow-700">• DPPs not found: {result.dpps_not_found}</li>
                )}
              </ul>
            </div>
          )}
        </div>

        <div className="mt-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
          <h2 className="font-semibold text-blue-900 mb-2">ℹ️ Instructions</h2>
          <ol className="text-sm text-blue-800 space-y-1 list-decimal list-inside">
            <li>Select a CSV file with planning insights data</li>
            <li>Click "Upload File" to process</li>
            <li>The system will automatically update matching DPPs</li>
            <li>Review the results to see how many DPPs were updated</li>
          </ol>
        </div>
      </div>
    </div>
  );
}
