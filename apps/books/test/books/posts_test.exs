defmodule Books.PostsTest do
  use Books.DataCase

  alias Books.Posts

  describe "post_categories" do
    alias Books.Posts.Category

    import Books.PostsFixtures

    @invalid_attrs %{"color" => nil, "name" => nil}

    test "list_post_categories/0 returns all post_categories" do
      post_category = post_category_fixture()
      assert post_category in Posts.list_categories()
    end

    test "get_post_category!/1 returns the post_category with given id" do
      post_category = post_category_fixture()
      assert Posts.get_category!(post_category.id) == post_category
    end

    test "create_post_category/1 with valid data creates a post_category" do
      valid_attrs = %{color: "some color", name: %{"en" => "some name"}}

      assert {:ok, %Category{} = post_category} = Posts.create_category(valid_attrs)
      assert post_category.color == "some color"
      assert post_category.name["en"] == "some name"
    end

    test "create_post_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Posts.create_category(@invalid_attrs)
    end

    test "update_post_category/2 with valid data updates the post_category" do
      post_category = post_category_fixture()
      update_attrs = %{color: "some updated color", name: %{"en" => "some updated name"}}

      assert {:ok, %Category{} = post_category} =
               Posts.update_category(post_category, update_attrs)

      assert post_category.color == "some updated color"
      assert post_category.name["en"] == "some updated name"
    end

    test "update_post_category/2 with invalid data returns error changeset" do
      post_category = post_category_fixture()
      assert {:error, %Ecto.Changeset{}} = Posts.update_category(post_category, @invalid_attrs)
      assert post_category == Posts.get_category!(post_category.id)
    end

    test "delete_post_category/1 deletes the post_category" do
      post_category = post_category_fixture()
      assert {:ok, %Category{}} = Posts.delete_category(post_category)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_category!(post_category.id) end
    end

    test "change_post_category/1 returns a post_category changeset" do
      post_category = post_category_fixture()
      assert %Ecto.Changeset{} = Posts.change_category(post_category)
    end
  end

  describe "post_tags" do
    alias Books.Posts.Tag

    import Books.PostsFixtures

    @invalid_attrs %{"name" => nil}

    test "list_post_tags/0 returns all post_tags" do
      tag = tag_fixture()
      assert Posts.list_tags() == [tag]
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Posts.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Tag{} = tag} = Posts.create_tag(valid_attrs)
      assert tag.name == "some name"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Posts.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Tag{} = tag} = Posts.update_tag(tag, update_attrs)
      assert tag.name == "some updated name"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Posts.update_tag(tag, @invalid_attrs)
      assert tag == Posts.get_tag!(tag.id)
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Posts.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = Posts.change_tag(tag)
    end
  end

  describe "posts" do
    alias Books.Posts.Post

    import Books.PostsFixtures
    import Books.CatalogFixtures

    @invalid_attrs %{
      "background_image" => nil,
      "content" => nil,
      "excerpt" => nil,
      "featured_image" => nil,
      "slug" => nil,
      "subtitle" => nil,
      "title" => nil
    }

    test "list_posts/0 returns all Spanish posts" do
      post = post_fixture(%{"lang" => "es"})
      assert Posts.list_posts("es") == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert Posts.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post" do
      category = post_category_fixture()
      author = author_fixture()

      valid_attrs = %{
        "background_image" => "some background_image",
        "content" => "some content",
        "excerpt" => "some excerpt",
        "featured_image" => "some featured_image",
        "slug" => "some slug",
        "subtitle" => "some subtitle",
        "title" => "some title",
        "category_id" => category.id,
        "author_id" => author.id
      }

      assert {:ok, %Post{} = post} = Posts.create_post(valid_attrs)
      assert post.background_image == "some background_image"
      assert post.content == "some content"
      assert post.excerpt == "some excerpt"
      assert post.featured_image == "some featured_image"
      assert post.slug == "some slug"
      assert post.subtitle == "some subtitle"
      assert post.title == "some title"
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Posts.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      old_post = post_fixture()

      update_attrs = %{
        "background_image" => "some updated background_image",
        "content" => "some updated content",
        "excerpt" => "some updated excerpt",
        "featured_image" => "some updated featured_image",
        "slug" => "some updated slug",
        "subtitle" => "some updated subtitle",
        "title" => "some updated title"
      }

      assert {:ok, %Post{} = post} = Posts.update_post(old_post, update_attrs)
      assert post.background_image == "some updated background_image"
      assert post.content == "some updated content"
      assert post.excerpt == "some updated excerpt"
      assert post.featured_image == "some updated featured_image"
      assert post.slug == "some updated slug"
      assert post.subtitle == "some updated subtitle"
      assert post.title == "some updated title"
      assert post.tags == old_post.tags
    end

    test "update_post/2 with invalid data returns error changeset" do
      post = post_fixture()
      assert {:error, %Ecto.Changeset{}} = Posts.update_post(post, @invalid_attrs)
      assert post == Posts.get_post!(post.id)
    end

    test "delete_post/1 deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = Posts.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Posts.change_post(post)
    end
  end

  describe "post_comments" do
    alias Books.Posts.Comment

    import Books.AccountsFixtures
    import Books.PostsFixtures

    @invalid_attrs %{"content" => nil}

    test "list_post_comments/0 returns all post_comments" do
      post = post_fixture()
      user = user_fixture()
      comment = comment_fixture(%{post_id: post.id, user_id: user.id})
      assert Posts.list_comments() == [comment]
    end

    test "get_comment!/1 returns the comment with given id" do
      post = post_fixture()
      user = user_fixture()
      comment = comment_fixture(%{post_id: post.id, user_id: user.id})
      assert Posts.get_comment!(comment.id) == comment
    end

    test "create_comment/1 with valid data creates a comment" do
      post = post_fixture()
      user = user_fixture()
      valid_attrs = %{content: "some content", post_id: post.id, user_id: user.id}

      assert {:ok, %Comment{} = comment} = Posts.create_comment(valid_attrs)
      assert comment.content == "some content"
    end

    test "create_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Posts.create_comment(@invalid_attrs)
    end

    test "update_comment/2 with valid data updates the comment" do
      post = post_fixture()
      user = user_fixture()
      comment = comment_fixture(%{post_id: post.id, user_id: user.id})
      update_attrs = %{content: "some updated content"}

      assert {:ok, %Comment{} = comment} = Posts.update_comment(comment, update_attrs)
      assert comment.content == "some updated content"
    end

    test "update_comment/2 with invalid data returns error changeset" do
      post = post_fixture()
      user = user_fixture()
      comment = comment_fixture(%{post_id: post.id, user_id: user.id})
      assert {:error, %Ecto.Changeset{}} = Posts.update_comment(comment, @invalid_attrs)
      assert comment == Posts.get_comment!(comment.id)
    end

    test "delete_comment/1 deletes the comment" do
      post = post_fixture()
      user = user_fixture()
      comment = comment_fixture(%{post_id: post.id, user_id: user.id})
      assert {:ok, %Comment{}} = Posts.delete_comment(comment)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_comment!(comment.id) end
    end

    test "change_comment/1 returns a comment changeset" do
      post = post_fixture()
      user = user_fixture()
      comment = comment_fixture(%{post_id: post.id, user_id: user.id})
      assert %Ecto.Changeset{} = Posts.change_comment(comment)
    end
  end
end
