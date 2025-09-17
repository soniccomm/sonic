function out = sort_files(folder,type)
files =dir (fullfile (folder ,'**' ,type));

num_files =length (files );
file_numbers =zeros (num_files ,1 );


for i =1 :num_files

    [~,file_name ]=fileparts (files (i ).name );


    try
        file_numbers (i )=str2double (file_name );
    catch

        file_numbers (i )=inf ;
    end
end


valid_indices =~isinf (file_numbers );
valid_files =files (valid_indices );
valid_numbers =file_numbers (valid_indices );


[~,sort_indices ]=sort (valid_numbers );
out  =valid_files (sort_indices );


end