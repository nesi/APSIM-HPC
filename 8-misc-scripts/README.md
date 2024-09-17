## `create_mock_db.file`

Default version of this script will:

- Create 5 files with names like *large_1.db, large_2.db*, etc., each between 21MB and 50MB in size.
- Create 5 files with names like *small_1.db, small_2.db*, etc., each between 1MB and 19MB in size.
- Use random data to fill the files.
- Show a progress bar for each file creation.

Please note:

- This script uses `/dev/urandom` as a source of random data, which might be slow for creating large files. For faster (but less random) file creation, you could replace `/dev/urandom` with `/dev/zero`.
- The exact sizes will vary each time you run the script due to the use of random numbers.
- The script will create files in the current directory.

<details>
</summary>Example</summary>
```bash
$ ./create_db_files.sh 
46+0 records in
46+0 records out
48234496 bytes (48 MB) copied, 0.330022 s, 146 MB/s
43+0 records in
43+0 records out
45088768 bytes (45 MB) copied, 0.279238 s, 161 MB/s
44+0 records in
44+0 records out
46137344 bytes (46 MB) copied, 0.26549 s, 174 MB/s
49+0 records in
49+0 records out
51380224 bytes (51 MB) copied, 0.335017 s, 153 MB/s
27+0 records in
27+0 records out
28311552 bytes (28 MB) copied, 0.167217 s, 169 MB/s
10+0 records in
10+0 records out
10485760 bytes (10 MB) copied, 0.0601622 s, 174 MB/s
13+0 records in
13+0 records out
13631488 bytes (14 MB) copied, 0.0829061 s, 164 MB/s
5+0 records in
5+0 records out
5242880 bytes (5.2 MB) copied, 0.0304713 s, 172 MB/s
3+0 records in
3+0 records out
3145728 bytes (3.1 MB) copied, 0.0186602 s, 169 MB/s
11+0 records in
11+0 records out
11534336 bytes (12 MB) copied, 0.0661401 s, 174 MB/s
File creation completed.
```
```bash
$ $ find ./ -name "*.db" -type f -exec du -h {} + | sort -rh
49M	./large_4.db
46M	./large_1.db
44M	./large_3.db
43M	./large_2.db
27M	./large_5.db
13M	./small_2.db
11M	./small_5.db
10M	./small_1.db
5.0M	./small_3.db
3.0M	./small_4.db
```
</details>

## `split_configfiles_to_sets.sh`

Default setting of this script will split .txt files in the current working directory to four separate directories, `set-1`, `set-2` , `set-3` and `set-4`