/*
    implementation of API
*/

#include "def.h"

pthread_mutex_t mutex_for_fs_stat;

//initialize file system - should be called as the first thing before accessing this file system 
int RSFS_init(){

    //initialize data blocks
    for(int i=0; i<NUM_DBLOCKS; i++){
      void *block = malloc(BLOCK_SIZE); //a data block is allocated from memory
      if(block==NULL){
        printf("[init] fails to init data_blocks\n");
        return -1;
      }
      data_blocks[i] = block;  
    } 

    //initialize bitmaps
    for(int i=0; i<NUM_DBLOCKS; i++) data_bitmap[i]=0;
    pthread_mutex_init(&data_bitmap_mutex,NULL);
    for(int i=0; i<NUM_INODES; i++) inode_bitmap[i]=0;
    pthread_mutex_init(&inode_bitmap_mutex,NULL);    

    //initialize inodes
    for(int i=0; i<NUM_INODES; i++){
        inodes[i].length=0;
        for(int j=0; j<NUM_POINTER; j++) 
            inodes[i].block[j]=-1; //pointer value -1 means the pointer is not used
        inodes[i].num_current_reader=0;
        pthread_mutex_init(&inodes[i].rw_mutex,NULL);
        pthread_mutex_init(&inodes[i].read_mutex,NULL);
    }
    pthread_mutex_init(&inodes_mutex,NULL); 

    //initialize open file table
    for(int i=0; i<NUM_OPEN_FILE; i++){
        struct open_file_entry entry=open_file_table[i];
        entry.used=0; //each entry is not used initially
        pthread_mutex_init(&entry.entry_mutex,NULL);
        entry.position=0;
        entry.access_flag=-1;
    }
    pthread_mutex_init(&open_file_table_mutex,NULL); 

    //initialize root directory
    root_dir.head = root_dir.tail = NULL;

    //initialize mutex_for_fs_stat
    pthread_mutex_init(&mutex_for_fs_stat,NULL);

    //return 0 means success
    return 0;
}


//create file
//if file does not exist, create the file and return 0;
//if file_name already exists, return -1; 
//otherwise, return -2.
int RSFS_create(char *file_name){

    //search root_dir for dir_entry matching provided file_name
    struct dir_entry *dir_entry = search_dir(file_name);

    if(dir_entry){//already exists
        printf("[create] file (%s) already exists.\n", file_name);
        return -1;
    }else{

        if(DEBUG) printf("[create] file (%s) does not exist.\n", file_name);

        //construct and insert a new dir_entry with given file_name
        dir_entry = insert_dir(file_name);
        if(DEBUG) printf("[create] insert a dir_entry with file_name:%s.\n", dir_entry->name);
        
        //access inode-bitmap to get a free inode 
        int inode_number = allocate_inode();
        if(inode_number<0){
            printf("[create] fail to allocate an inode.\n");
            return -2;
        } 
        if(DEBUG) printf("[create] allocate inode with number:%d.\n", inode_number);

        //save inode-number to dir-entry
        dir_entry->inode_number = inode_number;
        
        return 0;
    }
}



//open a file with RSFS_RDONLY or RSFS_RDWR flags
//When flag=RSFS_RDONLY: 
//  if the file is currently opened with RSFS_RDWR (by a process/thread)=> the caller should be blocked (wait); 
//  otherwise, the file is opened and the descriptor (i.e., index of the open_file_entry in the open_file_table) is returned
//When flag=RSFS_RDWR:
//  if the file is currently opened with RSFS_RDWR (by a process/thread) or RSFS_RDONLY (by one or multiple processes/threads) 
//      => the caller should be blocked (i.e. wait);
//  otherwise, the file is opened and the desrcriptor is returned
int RSFS_open(char *file_name, int access_flag){

    //to do: check to make sure access_flag is either RSFS_RDONLY or RSFS_RDWR
    if(access_flag != RSFS_RDONLY && access_flag != RSFS_RDWR){
        return -1;
    }
    //to do: find dir_entry matching file_name
    struct dir_entry *dir = search_dir(file_name);
    //to do: find the corresponding inode 
    struct inode node = inodes[dir->inode_number];
    
    //to do: base on the requested access_flag and the current "open" status of this file to block the caller if needed
    //(refer to solution to reader/writer problem)
    if(access_flag == RSFS_RDONLY){
        pthread_mutex_lock(&node.read_mutex);
        while(node.num_current_reader > 0){
            pthread_mutex_unlock(&node.read_mutex);
            sleep(1);
            pthread_mutex_lock(&node.read_mutex);
        }
        pthread_mutex_unlock(&node.read_mutex);
    }else if(access_flag == RSFS_RDWR){
        pthread_mutex_lock(&node.rw_mutex);
        while(node.num_current_reader > 0){
            pthread_mutex_unlock(&node.rw_mutex);
            sleep(1);
            pthread_mutex_lock(&node.rw_mutex);
        }
        pthread_mutex_unlock(&node.rw_mutex);
    }

    //to do: find an unused open-file-entry in open-file-table and fill the fields of the entry properly
    int loc = allocate_open_file_entry(access_flag, dir);

    //to do: return the index of the open-file-entry in open-file-table as file descriptor
    return loc; //placeholder
}



//append the content in buf to the end of the file of descriptor fd
int RSFS_append(int fd, void *buf, int size){

    //to do: check the sanity of the arguments: fd should be in [0,NUM_OPEN_FILE] and size>0.
    if(fd < 0 || fd > NUM_OPEN_FILE || size < 0){
        return -1;
    }
    //to do: get the open file entry corresponding to fd
    struct open_file_entry *entry = &open_file_table[fd];
    //to do: check if the file is opened with RSFS_RDWR mode; otherwise return -1
    if(entry->access_flag != RSFS_RDWR){
        return -1;
    }
    pthread_mutex_lock(&entry->entry_mutex);
    //get the current position
    int pos = entry->position;
    //to do: get the corresponding directory entry
    struct dir_entry dir;
    memcpy(&dir, entry->dir_entry, sizeof(struct dir_entry));
    //to do: get the corresponding inode 
    struct inode *node = &inodes[entry->dir_entry->inode_number];
    pthread_mutex_lock(&node->rw_mutex);

    //to do: append the content in buf to the data blocks of the file from the end of the file; 
    //allocate new block(s) when needed - (refer to lecture L22 on how)
    //new data blocks may be allocated for the file if needed
    int min = 0;
    if(size < (NUM_POINTER * BLOCK_SIZE) - entry->position){
        min = size;
    }else{
        min = (NUM_POINTER * BLOCK_SIZE) - entry->position;
    }
    int added = 0;
    //loop through the data blocks that will be allocated
    for (int i = entry->position; i < min; i++)
    {
        int block = (i + entry->position) / BLOCK_SIZE;
        int offset = (i + entry->position) % BLOCK_SIZE;

        if (node->block[block] < 0)
        {
            int blockNum = allocate_data_block();
            if (blockNum == -1)
            {
                // fs out of data blocks, return error
                node->length += (i - (entry->position - node->length));
                entry->position += i;
                pthread_mutex_unlock(&entry->entry_mutex);
                return -1;
            }
            data_blocks[blockNum] = (void *)malloc(BLOCK_SIZE);
            node->block[block] = blockNum;
        }
        void *pos = data_blocks[node->block[block]];
        memcpy(data_blocks[node->block[block]] + offset, buf + i, 1);
        ++added;
    }
     
    //to do: update the current position in open file entry
    entry->position = pos;
    node->length += added;
    pthread_mutex_unlock(&node->rw_mutex);
    pthread_mutex_unlock(&entry->entry_mutex);
    //to do: return the number of bytes appended to the file
    return added; //placeholder
}

//update current position of the file (which is in the open_file_entry) to offset
int RSFS_fseek(int fd, int offset){

    //to do: sanity test of fd    
    if(fd < 0 && fd >= NUM_OPEN_FILE || !open_file_table[fd].used){
        return -1;
    }
    //to do: get the correspondng open file entry
    struct open_file_entry *entry = &open_file_table[fd];
    pthread_mutex_lock(&entry->entry_mutex);
    //to do: get the current position
    int pos = entry->position;
    //to do: get the corresponding dir entry
    //to do: get the corresponding inode and file length
    struct inode node = inodes[entry->dir_entry->inode_number];
    pthread_mutex_lock(&node.read_mutex);
    //to do: check if argument offset is not within 0...length, do not proceed and return current position
    if(offset >= 0 && offset <= node.length){
        pos = offset;
        entry->position = pos;
    }
    pthread_mutex_unlock(&node.read_mutex);
    pthread_mutex_unlock(&entry->entry_mutex);
    //to do: update the current position to offset, and return the new current position
    //I did this in my if statement above'
    //to do: return the current poisiton
    return pos; //placeholder
}

//read from file from the current position for up to size bytes
int RSFS_read(int fd, void *buf, int size){

    //to do: sanity test of fd and size    
    if(fd < 0 || size <= 0){
        return -1;
    }
    //to do: get the corresponding open file entry
    struct open_file_entry *entry = &open_file_table[fd];
    pthread_mutex_lock(&entry->entry_mutex);
    //to do: get the current position
    int pos = entry->position;
    //to do: get the corresponding directory entry
    struct dir_entry dir;
    memcpy(&dir, entry->dir_entry, sizeof(struct dir_entry));
    //to do: get the corresponding inode 
    struct inode *node = &inodes[entry->dir_entry->inode_number];
    pthread_mutex_lock(&node->read_mutex);
    //to do: read the content of the file from current position for up to size bytes 
    int min;
    if(size < node->length - entry->position){
        min = size;
    }else{
        min = node->length - entry->position;
    }
    for(int i = 0; i < min; ++i){ 
        int offset = (i + entry->position) % BLOCK_SIZE;
        int block = (i + entry->position) / BLOCK_SIZE;
        //if we get to a block that may not be allocated just go on through the loop
        if (node->block[block] < 0 || data_blocks[node->block[block]] == NULL) {
            continue; 
        }
        memcpy(buf + i, data_blocks[node->block[block]] + offset, 1);
    }

    //find the amount read;
    if(size < node->length - entry->position){
        min = size;
    }else{
        min = node->length - entry->position;
    }
    int numRead = min;

    //to do: update the current position in open file entry
    entry->position = numRead;
    pthread_mutex_unlock(&node->read_mutex);
    pthread_mutex_unlock(&entry->entry_mutex);
    //to do: return the actual number of bytes read
    return numRead; //placeholder 
}


//close file: return 0 if succeed
int RSFS_close(int fd){

    //to do: sanity test of fd and whence    
    if(fd < 0){
        return -1;
    }
    //to do: get the corresponding open file entry
    struct open_file_entry entry = open_file_table[fd];
    pthread_mutex_lock(&entry.entry_mutex);
    //to do: get the corresponding dir entry
    struct dir_entry dir;
    memcpy(&dir, entry.dir_entry, sizeof(struct dir_entry));
    //to do: get the corresponding inode 
    struct inode curr = inodes[dir.inode_number];
    pthread_mutex_lock(&curr.rw_mutex);
    //to do: depending on the way that the file was open (RSFS_RDONLY or RSFS_RDWR), update the corresponding mutex and/or count 
    //(refer to the solution to the readers/writers problem)
    if(entry.access_flag == RSFS_RDONLY){
        curr.num_current_reader--;
    }else if (entry.access_flag == RSFS_RDWR){
        curr.num_current_reader--;
    }
    pthread_mutex_unlock(&curr.rw_mutex);
    pthread_mutex_unlock(&entry.entry_mutex);
    //to do: release this open file entry in the open file table
    free_open_file_entry(fd);
    return 0;
}


//delete file
int RSFS_delete(char *file_name){

    //to do: find the corresponding dir_entry
    struct dir_entry *dir = search_dir(file_name);
    struct inode node = inodes[dir->inode_number];
    pthread_mutex_lock(&node.rw_mutex);
    //to do: find the corresponding inode
    //to do: free the inode in inode-bitmap
    node.length = 0;
    for(int i = 0; i < 8; ++i){
        free_data_block(inodes[dir->inode_number].block[i]);
    }

    pthread_mutex_lock(&open_file_table_mutex);
    for(int i = 0; i < NUM_OPEN_FILE; ++i){
        if(open_file_table[i].dir_entry->inode_number == dir->inode_number){
            open_file_table[i].used = 0;
        }
    }
    delete_dir(file_name);
    free_inode(dir->inode_number);
    pthread_mutex_unlock(&open_file_table_mutex);
    pthread_mutex_unlock(&node.rw_mutex);
    return 0;
}


//print status of the file system
void RSFS_stat(){

    pthread_mutex_lock(&mutex_for_fs_stat);

    printf("\nCurrent status of the file system:\n\n %16s%10s%10s\n", "File Name", "Length", "iNode #");

    //list files
    struct dir_entry *dir_entry = root_dir.head;
    while(dir_entry!=NULL){

        int inode_number = dir_entry->inode_number;
        struct inode *inode = &inodes[inode_number];
        
        printf("%16s%10d%10d\n", dir_entry->name, inode->length, inode_number);
        dir_entry = dir_entry->next;
    }
    
    //data blocks
    int db_used=0;
    for(int i=0; i<NUM_DBLOCKS; i++) db_used+=data_bitmap[i];
    printf("\nTotal Data Blocks: %4d,  Used: %d,  Unused: %d\n", NUM_DBLOCKS, db_used, NUM_DBLOCKS-db_used);

    //inodes
    int inodes_used=0;
    for(int i=0; i<NUM_INODES; i++) inodes_used+=inode_bitmap[i];
    printf("Total iNode Blocks: %3d,  Used: %d,  Unused: %d\n", NUM_INODES, inodes_used, NUM_INODES-inodes_used);

    //open files
    int of_num=0;
    for(int i=0; i<NUM_OPEN_FILE; i++) of_num+=open_file_table[i].used;
    printf("Total Opened Files: %3d\n\n", of_num);

    pthread_mutex_unlock(&mutex_for_fs_stat);
}



//write the content of size (bytes) in buf to the file (of descripter fd) from current position for up to size bytes 
//returns the size change
int RSFS_write(int fd, void *buf, int size){
    //ensure that this is a real file in our system
    if (fd < 0 || fd >= NUM_OPEN_FILE || !open_file_table[fd].used || size < 0)
    {
        return -1;
    }

    //get file data to be used
    struct open_file_entry *entry = &open_file_table[fd];    
    pthread_mutex_lock(&entry->entry_mutex);
    struct inode *node = &inodes[entry->dir_entry->inode_number];
    pthread_mutex_lock(&node->rw_mutex);

    //new data blocks may be allocated for the file if needed
    int min = 0;
    if(size < (NUM_POINTER * BLOCK_SIZE) - entry->position){
        min = size;
    }else{
        min = (NUM_POINTER * BLOCK_SIZE) - entry->position;
    }

    //put data into datablocks
    for (int i = 0; i < min; i++)
    {
        int block = (i + entry->position) / BLOCK_SIZE;
        int offset = (i + entry->position) % BLOCK_SIZE;

        if (node->block[block] < 0)
        {
            int blockNum = allocate_data_block();
            if (blockNum == -1)
            {
                //If we hit a point where we don't have any other datablocks when return the function
                node->length += (i - (entry->position - node->length));
                entry->position += i;
                pthread_mutex_unlock(&entry->entry_mutex);
                return -1;
            }
            data_blocks[blockNum] = (void *)malloc(BLOCK_SIZE);
            node->block[block] = blockNum;
        }
        void *pos = data_blocks[node->block[block]];
        memcpy(data_blocks[node->block[block]] + offset, buf + i, 1);
    }
    //check the actual change in the blocks
    if(size < (NUM_POINTER * BLOCK_SIZE) - entry->position){
        min = size;
    }else{
        min = (NUM_POINTER * BLOCK_SIZE) - entry->position;
    }
    int sChange = min;
    node->length += sChange - (entry->position - node->length);
    entry->position += sChange;

    //unlock the open file entry
    pthread_mutex_unlock(&node->rw_mutex);
    pthread_mutex_unlock(&entry->entry_mutex);

    //return the current position
    return sChange;
}


//cut the content from the current position for up to size (bytes) from the file of descriptor fd
int RSFS_cut(int fd, int size){
    if (fd < 0 || fd >= NUM_OPEN_FILE || size < 0) {
        return -1;
    }

    //Get needed file storage data
    struct open_file_entry *entry = &open_file_table[fd];
    pthread_mutex_lock(&entry->entry_mutex);
    struct inode *node = &inodes[entry->dir_entry->inode_number];
    pthread_mutex_lock(&node->rw_mutex);

    //Figure out where to cut and how far we actually cut
    int cut = (size < (node->length - entry->position)) ? size : (node->length - entry->position);
    int endpos = entry->position + cut;
    node->length -= cut;

    // If the end position is within the same block, just update the position
    if (entry->position / BLOCK_SIZE == endpos / BLOCK_SIZE) {
        entry->position = endpos;
    } else {
        // Otherwise, adjust the block pointers
        int start = entry->position / BLOCK_SIZE;
        int end = endpos / BLOCK_SIZE;
        int overflow = endpos % BLOCK_SIZE;

        // Shift blocks accordingly
        for (int i = end + 1; i <= node->length / BLOCK_SIZE; i++) {
            node->block[i - (end - start) - 1] = node->block[i];
        }

        // Update the position
        entry->position = (end * BLOCK_SIZE) + overflow;
    }

    // Unlock the open file entry
    pthread_mutex_unlock(&node->rw_mutex);
    pthread_mutex_unlock(&entry->entry_mutex);

    return cut;
}