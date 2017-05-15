function integer clog2(input integer value);
begin
        if(value==0)
            clog2=0;
        else
        begin
            while(value>0)
            begin
                clog2=clog2+1;
                value=value>>1;    
            end    
        end
end
endfunction 
