#!/bin/bash

release_remote_ctl rpc "Mix.Tasks.Books.Post.run([\"$1\"])"
