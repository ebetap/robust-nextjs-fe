#!/bin/bash

# Step 1: Create necessary directories and files
mkdir -p src/app
touch src/app/api.js
touch src/app/store.js
mkdir -p pages/posts
touch pages/posts/index.js
touch pages/posts/[postId].js

# Step 2: Install dependencies
npm install @reduxjs/toolkit react-redux axios

# Step 3: Generate API slice with CRUD operations
cat <<EOF > src/app/api.js
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

const api = createApi({
  reducerPath: 'api',
  baseQuery: fetchBaseQuery({ baseUrl: '/api' }), // Replace with your API base URL
  endpoints: (builder) => ({
    getPosts: builder.query({
      query: () => 'posts',
    }),
    getPostById: builder.query({
      query: (postId) => \`posts/\${postId}\`,
    }),
    addPost: builder.mutation({
      query: (newPost) => ({
        url: 'posts',
        method: 'POST',
        body: newPost,
      }),
    }),
    updatePost: builder.mutation({
      query: ({ postId, updatedPost }) => ({
        url: \`posts/\${postId}\`,
        method: 'PUT',
        body: updatedPost,
      }),
    }),
    deletePost: builder.mutation({
      query: (postId) => ({
        url: \`posts/\${postId}\`,
        method: 'DELETE',
      }),
    }),
  }),
});

export const {
  useGetPostsQuery,
  useGetPostByIdQuery,
  useAddPostMutation,
  useUpdatePostMutation,
  useDeletePostMutation,
} = api;

export default api;
EOF

# Step 4: Configure Redux store
cat <<EOF > src/app/store.js
import { configureStore } from '@reduxjs/toolkit';
import api from './api';

const store = configureStore({
  reducer: {
    [api.reducerPath]: api.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware().concat(api.middleware),
});

export default store;
EOF

# Step 5: Integrate Redux Provider in _app.js
cat <<EOF > pages/_app.js
import { Provider } from 'react-redux';
import store from '../src/app/store';

function MyApp({ Component, pageProps }) {
  return (
    <Provider store={store}>
      <Component {...pageProps} />
    </Provider>
  );
}

export default MyApp;
EOF

# Step 6: Create example components for CRUD operations
cat <<EOF > pages/posts/index.js
import { useEffect } from 'react';
import Link from 'next/link';
import { useGetPostsQuery, useDeletePostMutation } from '../../src/app/api';

function PostsList() {
  const { data: posts, error, isLoading, refetch } = useGetPostsQuery();
  const [deletePost, { isLoading: isDeleting }] = useDeletePostMutation();

  const handleDelete = async (postId) => {
    try {
      await deletePost(postId);
      refetch(); // Refresh the posts after deletion
    } catch (error) {
      console.error('Failed to delete the post:', error.message);
    }
  };

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      <h1>Posts List</h1>
      <Link href="/posts/new">
        <a>Add New Post</a>
      </Link>
      <ul>
        {posts.map((post) => (
          <li key={post.id}>
            <Link href={`/posts/\${post.id}`}>
              <a>{post.title}</a>
            </Link>
            <button onClick={() => handleDelete(post.id)} disabled={isDeleting}>
              Delete
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default PostsList;
EOF

cat <<EOF > pages/posts/[postId].js
import { useRouter } from 'next/router';
import { useState } from 'react';
import { useGetPostByIdQuery, useUpdatePostMutation } from '../../src/app/api';

function EditPost() {
  const router = useRouter();
  const { postId } = router.query;
  const { data: post, error, isLoading } = useGetPostByIdQuery(postId);
  const [updatedPost, setUpdatedPost] = useState(post);
  const [updatePost, { isLoading: isUpdating }] = useUpdatePostMutation();

  const handleChange = (e) => {
    setUpdatedPost({ ...updatedPost, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await updatePost({ postId, updatedPost });
      router.push('/posts'); // Redirect after successful update
    } catch (error) {
      console.error('Failed to update the post:', error.message);
    }
  };

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      <h1>Edit Post</h1>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          name="title"
          value={updatedPost.title}
          onChange={handleChange}
          required
        />
        <textarea
          name="body"
          value={updatedPost.body}
          onChange={handleChange}
          required
        />
        <button type="submit" disabled={isUpdating}>
          Update Post
        </button>
      </form>
    </div>
  );
}

export default EditPost;
EOF

# Output success message
echo "Redux Toolkit Query setup completed successfully!"
