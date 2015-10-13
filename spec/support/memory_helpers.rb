# encoding: UTF-8
#
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

KB = 1024
MB = 1024 * KB
GB = 1024 * MB

# Some test helpers related with system memory and swap files.
# Translates bytes to values used by real systems.
module MemoryHelpers
  def system_memory(bytes)
    "#{(bytes / 1024).round}kB"
  end

  def system_swap(*args)
    system_memory(*args)
  end

  def swap_file_size(bytes)
    (bytes / MB).round
  end
end
