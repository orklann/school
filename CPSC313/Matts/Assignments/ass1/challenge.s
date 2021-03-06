#
# Calling conventions:
#     %eax, %ebx, %ecx, %edx can be used by subroutines without saving.
#     %ebp, %esi, %edi must be saved and restored if they are used.
#     %esp can not be used except for its normal use as a stack pointer.
#
#     argument are passed through registers %eax, %ebx, except for subroutine
#     heapify_node_helper (see its documentation).
#
#     values are returned through %eax
#
.pos 0x100

main:	irmovl bottom,  %esp     # initialize stack

	xorl   %eax, %eax        # %eax = 0
	mrmovl size(%eax), %eax  # %eax = size
	irmovl $1, %ebx
	subl   %ebx, %eax        # %eax = size - 1
	
	
###
### THIS PART IS THE START OF THE CHALLENGE
###
	call	heapify_array	#heapify array to be used
	irmovl 	$19, %eax
	call	insert
		
	halt
	
	
#
# Insert
#	%eax: element to be inserted into heap
#
insert:
	### This inserts
	xorl   	%edx, %edx			
	mrmovl 	size(%edx), %ecx  	# %eax = size
	irmovl 	$4, %edx
	mull	%edx, %ecx
	rmmovl	%eax, heap(%ecx)	

	xorl   	%ecx, %ecx			# %ecx = 0
	mrmovl 	size(%ecx), %ecx  	# %ecx = size
	pushl	%ecx				# save last position
	
	irmovl 	$1, %edx				
	subl   	%edx, %ecx       	# %ecx = last
	irmovl 	$2, %edx			# 
	divl	%edx, %ecx			# (i-1)/2, Find parent position
	pushl	%ecx				# save parent's position
	irmovl 	$4, %edx			#
	mull	%edx, %ecx			# multiply offset of the parent's position
	mrmovl 	heap(%ecx), %ecx	# %ecx = parent node of last postion
	subl	%eax, %ecx			# ecx-eax
	jge		done
	
loop1:
	popl 	%ecx	
	popl 	%eax	
	pushl	%eax	
	
	irmovl 	$4, %edx
	mull	%edx, %ecx
	mull	%edx, %eax
	
	mrmovl 	heap(%ecx), %ebx
	rmmovl	%ebx, heap(%eax)
	mrmovl 	heap(%eax), %ebx
	rrmovl	%ebx, %eax
	rmmovl	%ebx, heap(%ecx)
	
	popl	%ecx
	pushl	%ecx
	irmovl 	$1, %edx				
	subl   	%edx, %ecx       	# %ecx = last
	irmovl 	$2, %edx
	divl	%edx, %ecx			# (i-1)/2, Find parent position
	pushl	%ecx
	irmovl 	$4, %edx			#
	mull	%edx, %ecx			# multiply offset of the parent's position
	mrmovl 	heap(%ecx), %ecx	# %ecx = parent node of last postion
	subl	%eax, %ecx			# ecx-eax
	jl		loop
	
	
done:
	popl %eax
	popl %eax
	
	xorl   %edx, %edx        	# %edx = 0
	mrmovl size(%edx), %edx  	# %edx = size
	irmovl $1, %ebx
	addl   %ebx, %edx       	# %edx = size + 1
	xorl   %ebx, %ebx			# %ebx = 0
	rmmovl	%edx, size(%ebx)
	
	
	ret
	

#
# Swap:
#    %eax: index1
#    %ebx: index2
#
swap:	addl   %eax, %eax	# Offset is 4 times the index
	addl   %eax, %eax
	addl   %ebx, %ebx	# Offset is 4 times the index
	addl   %ebx, %ebx
	
	mrmovl heap(%eax), %ecx # tmp = heap[index1]
	mrmovl heap(%ebx), %edx # heap[index1] = heap[index2]
	rmmovl %edx, heap(%eax)
	rmmovl %ecx, heap(%ebx) # heap[index2] = tmp

	ret

#
# Check_child
#     %ecx: child index
#     %esi: index of highest
#     %ebp: last
# Returns:
#     %eax: true if child <= last && heap[highest] < heap[child]
#
check_child:
	pushl  %edi
	xorl   %eax, %eax       # set return value to false.

	rrmovl %ecx, %edi       # if child > last, skip
	subl   %ebp, %edi
	jg     check_child_finish

	rrmovl %esi, %edi       # %edi = heap[highest]
	addl   %edi, %edi
	addl   %edi, %edi
	mrmovl heap(%edi), %edi

	rrmovl %ecx, %edx       # %edx = heap[child]
	addl   %edx, %edx
	addl   %edx, %edx
	mrmovl heap(%edx), %edx

	irmovl $1,   %ebx
	subl   %edi, %edx      # if heap[child] > heap[highest], return 1
	cmovg  %ebx, %eax

check_child_finish:
	popl %edi
	ret

#
# Heapify_node
#     %eax: index
#     %ebx: last
#
# Local variables:
#     %ecx: left_child, right_child, need_to_swap
#     %esi: highest
#     %edi: index
#     %ebp: last
#
heapify_node:
	pushl  %edi             # Save %edi and use it to store index
	rrmovl %eax, %edi
	pushl  %esi		# Save %esi and use it to store highest
	rrmovl %eax, %esi
	pushl  %ebp
	rrmovl %ebx, %ebp

heapify_loop:
	rrmovl %edi, %ecx       # left_child = 2 * index + 1
	addl   %ecx, %ecx
	irmovl $1,   %edx
	addl   %edx, %ecx

	call   check_child
	andl   %eax, %eax
	cmovne %ecx, %esi       # highest = left_child (if condition ok)

	irmovl $1, %edx		# right_child = 2 * index + 2
	addl   %edx, %ecx

	call   check_child
	andl   %eax, %eax
	cmovne %ecx, %esi       # highest = right_child (if condition ok)

heapify_skip2:
	rrmovl %esi, %eax
	subl   %edi, %eax
	je     heapify_finish

	rrmovl %esi, %eax
	rrmovl %edi, %ebx
	call   swap

	rrmovl %esi, %edi
	jmp    heapify_loop

heapify_finish:
	popl   %ebp
	popl   %esi
	popl   %edi
	ret
	
	
# Heapify_array
#     %eax: last
#
heapify_array:
	pushl  %esi             # Save %esi and use it to store 'last'
	rrmovl %eax, %esi
	pushl  %edi             # Save %edi before using it for i

	irmovl $1, %ebx		# %eax = last - 1
	subl   %ebx, %eax
	irmovl $2, %ebx		# %eax = (last - 1)/2
	divl   %ebx, %eax
	rrmovl %eax, %edi       # i = %eax
	
ha_loop:
	andl   %edi, %edi       # check if i < 0
	jl     ha_finish

	rrmovl %edi, %eax       # Set %eax = i, %ebx = last      
	rrmovl %esi, %ebx
	call   heapify_node     # Heapify the node

	irmovl $1, %eax         # i--
	subl   %eax, %edi
	jmp    ha_loop

ha_finish:
	popl   %edi
	popl   %esi
	ret
	
#
# Extract_max
#     %eax: last
#
extract_max:
	pushl  %esi		# Save %esi before using it for max

	xorl   %ebx, %ebx       # max = heap[0]
	mrmovl heap(%ebx), %esi

	rrmovl %eax, %edx
	addl   %edx, %edx       # %ecx = heap[last]
	addl   %edx, %edx
	mrmovl heap(%edx), %ecx 
	rmmovl %ecx, heap(%ebx) # heap[0] = %ecx

	rrmovl %eax, %ebx	# %ebx = last - 1
	irmovl $1, %ecx
	subl   %ecx, %ebx
	xorl   %eax, %eax       # %eax = 0
	call   heapify_node     # Heapify the root

	rrmovl %esi, %eax       # Set return value to max
	popl   %esi
	ret

#
# Heapsort
#    %eax: last
#
heapsort:
	pushl	%eax			# Save the value of last
	call	heapify_array	# Call heapify_array
	popl	%eax			# Recall the value of last
	xorl	%ecx, %ecx		# %ecx = 0
	subl 	%ecx, %eax		# Check to see if last < 0
	jl		end				# If so, done
	
loop:
	pushl	%eax			# Save the value of i [or last]
	call	extract_max		# Call extract_max
	popl	%ecx			# %eci = i, load back i [or last] for use
	pushl	%ecx			# Save the value of i [or last] again
	irmovl	$0x4, %edx		# %edx = 4
	mull	%edx, %ecx		# ecx *= 4, for offset of heap address
	rmmovl	%eax, heap(%ecx)	#Store the value obtain in extract_max into heap[i]
	irmovl	$0x1, %edx		# %edx = 1
	popl	%ecx			# Load the value of i [or last]
	subl	%edx, %ecx		# i--, decrement i
	rrmovl	%ecx, %eax		# %eax = %ecx, for preparation of the loop
	jge		loop			# Check to if i >= 0, if so repeat 
end:
	ret						# Done, Hurrah!
	
###
### THIS PART TO BE COMPLETED BY THE STUDENT.
###

#
# Array to sort
#
.pos 0x1000
heap:	.long 4
        .long 15
        .long 6
        .long 2
        .long 21
	.long 17
	.long 11
	.long 16
	.long 8
	.long 13
	.long 14
	.long 1
	.long 9
	.long 0
	.long 0

size:   .long 13
	
#
# Stack (32 thirty-two bit words is more than enough here).
#
.pos 0x3000
top:	            .long 0x00000000,0x20     # top of stack.
bottom:             .long 0x00000000          # bottom of stack.
